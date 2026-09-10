import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/repositories/invoice_repository.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';

enum InvoiceListFilter { all, draft, unpaid, overdue, paid, cancelled }

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider(this._repository, {NotificationRepository? notifications})
    : _notifications = notifications;

  final InvoiceRepository _repository;
  final NotificationRepository? _notifications;

  StreamSubscription<List<Invoice>>? _subscription;
  String? _businessId;
  String _currencyCode = AppConstants.defaultCurrencyCode;
  List<Invoice> _invoices = const [];
  String _query = '';
  InvoiceListFilter _filter = InvoiceListFilter.all;
  int _pageSize = AppConstants.listPageSize;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _saving = false;
  String? _error;

  String? get businessId => _businessId;
  String get currencyCode => _currencyCode;
  List<Invoice> get allInvoices => _invoices;
  String get query => _query;
  InvoiceListFilter get filter => _filter;
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get isSaving => _saving;
  String? get error => _error;

  List<Invoice> get visibleInvoices {
    final now = DateTime.now();
    var list = _invoices;
    if (_query.trim().isNotEmpty) {
      list = list.where((invoice) => invoice.matches(_query)).toList();
    }
    switch (_filter) {
      case InvoiceListFilter.all:
        break;
      case InvoiceListFilter.draft:
        list = list.where((invoice) => invoice.isDraft).toList();
      case InvoiceListFilter.unpaid:
        list = list.where((invoice) {
          if (invoice.isDraft || invoice.isCancelled) return false;
          if (invoice.status == InvoiceStatus.paid || !invoice.outstanding.isPositive) return false;
          return !invoice.isOverdue(now);
        }).toList();
      case InvoiceListFilter.overdue:
        list = list.where((invoice) => invoice.isOverdue(now)).toList();
      case InvoiceListFilter.paid:
        list = list.where((invoice) {
          return !invoice.isDraft &&
              !invoice.isCancelled &&
              (invoice.status == InvoiceStatus.paid || !invoice.outstanding.isPositive);
        }).toList();
      case InvoiceListFilter.cancelled:
        list = list.where((invoice) => invoice.isCancelled).toList();
    }
    return list;
  }

  Invoice? byId(String invoiceId) {
    for (final invoice in _invoices) {
      if (invoice.id == invoiceId) return invoice;
    }
    return null;
  }

  void bind({String? businessId, String currencyCode = AppConstants.defaultCurrencyCode}) {
    _currencyCode = currencyCode;
    if (businessId == _businessId && _subscription != null) return;
    unawaited(_resubscribe(businessId, resetPageSize: true));
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || _businessId == null || _businessId!.isEmpty) return;
    _loadingMore = true;
    notifyListeners();
    _pageSize += AppConstants.listPageSize;
    await _resubscribe(_businessId, resetPageSize: false, showFullLoading: false);
  }

  Future<void> _resubscribe(
    String? businessId, {
    required bool resetPageSize,
    bool showFullLoading = true,
  }) async {
    await _subscription?.cancel();
    _subscription = null;
    _businessId = businessId;
    if (resetPageSize) {
      _pageSize = AppConstants.listPageSize;
      _invoices = const [];
    }
    _error = null;

    if (businessId == null || businessId.isEmpty) {
      _loading = false;
      _loadingMore = false;
      _hasMore = false;
      notifyListeners();
      return;
    }

    if (showFullLoading) {
      _loading = true;
      notifyListeners();
    }
    _subscription = _repository.watchAll(businessId, limit: _pageSize).listen(
      (value) {
        _invoices = value;
        _hasMore = value.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Invoice watch failed', error, stack);
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load invoices.';
        notifyListeners();
      },
    );
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setFilter(InvoiceListFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  String nextId() {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return _repository.newId(businessId);
  }

  void _assertReadyToSave(Invoice invoice, {required bool issuing}) {
    if (invoice.customerId.isEmpty || invoice.customerName.trim().length < 2) {
      throw const AppException(AppStrings.invoiceNeedsCustomer, debugCode: 'invoice-customer');
    }
    if (issuing && invoice.items.isEmpty) {
      throw const AppException(AppStrings.invoiceNeedsItems, debugCode: 'invoice-items');
    }
    if (issuing && !invoice.total.isPositive) {
      throw const AppException(AppStrings.invoiceNeedsTotal, debugCode: 'invoice-total');
    }
    if (AppDateFormatter.startOfDay(invoice.dueDate).isBefore(AppDateFormatter.startOfDay(invoice.issueDate))) {
      throw const AppException(AppStrings.dueBeforeIssue, debugCode: 'invoice-dates');
    }
  }

  Future<Invoice> save(Invoice draft, {required Business business, required bool asDraft}) async {
    _assertReadyToSave(draft, issuing: !asDraft);
    if (!asDraft && !draft.canIssue && !draft.canEdit) {
      throw const AppException(AppStrings.cannotEditInvoice, debugCode: 'invoice-locked');
    }
    final existing = byId(draft.id);
    final toStore = asDraft
        ? draft.copyWith(status: existing?.isDraft == false ? existing!.status : InvoiceStatus.draft)
        : draft.copyWith(status: existing == null || existing.isDraft ? InvoiceStatus.unpaid : existing.status);

    _saving = true;
    notifyListeners();
    try {
      if (existing == null) {
        final created = await _repository.create(invoice: toStore, business: business);
        await _notifyIssued(created);
        return created;
      }
      if (!existing.canEdit) {
        throw const AppException(AppStrings.cannotEditInvoice, debugCode: 'invoice-locked');
      }
      await _repository.update(toStore);
      if (existing.isDraft && !toStore.isDraft) {
        await _notifyIssued(toStore);
      }
      return toStore;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<Invoice> markSent(Invoice invoice) async {
    if (!invoice.canMarkSent) {
      throw const AppException(AppStrings.cannotEditInvoice, debugCode: 'invoice-locked');
    }
    return _updateStatus(invoice, InvoiceStatus.sent);
  }

  Future<Invoice> cancel(Invoice invoice) async {
    if (!invoice.canCancel) {
      throw const AppException(AppStrings.cannotCancelInvoice, debugCode: 'invoice-locked');
    }
    return _updateStatus(invoice, InvoiceStatus.cancelled);
  }

  Future<Invoice> duplicate(Invoice invoice, {required Business business, required DateTime now}) async {
    final clone = Invoice.draft(
      id: nextId(),
      business: business,
      now: now,
      paymentTerms: invoice.paymentTerms,
    )
        .withItems(invoice.items)
        .copyWith(
          customerId: invoice.customerId,
          customerName: invoice.customerName,
          customerCompany: invoice.customerCompany,
          customerEmail: invoice.customerEmail,
          customerPhone: invoice.customerPhone,
          customerAddress: invoice.customerAddress,
          customerCity: invoice.customerCity,
          notes: invoice.notes,
          dueDate: invoice.paymentTerms == InvoicePaymentTerms.custom
              ? invoice.dueDate
              : invoice.paymentTerms.dueDateFrom(AppDateFormatter.startOfDay(now)),
        );
    _saving = true;
    notifyListeners();
    try {
      return await _repository.create(invoice: clone, business: business);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<Invoice> _updateStatus(Invoice invoice, InvoiceStatus status) async {
    _saving = true;
    notifyListeners();
    try {
      final updated = invoice.copyWith(status: status);
      await _repository.update(updated);
      return updated;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> delete(Invoice invoice) async {
    _saving = true;
    notifyListeners();
    try {
      await _repository.delete(invoice);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> _notifyIssued(Invoice invoice) async {
    if (invoice.isDraft) return;
    final notifications = _notifications;
    if (notifications == null) return;
    try {
      await notifications.upsert(AppNotification.invoiceCreated(invoice));
    } catch (error, stack) {
      AppLogger.error('Invoice created notification failed', error, stack);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
