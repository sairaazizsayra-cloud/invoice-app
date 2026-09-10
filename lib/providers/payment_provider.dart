import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';
import 'package:invoice_pro/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this._repository, {NotificationRepository? notifications})
    : _notifications = notifications;

  final PaymentRepository _repository;
  final NotificationRepository? _notifications;

  StreamSubscription<List<Payment>>? _subscription;
  String? _businessId;
  String _currencyCode = AppConstants.defaultCurrencyCode;
  List<Payment> _payments = const [];
  int _pageSize = AppConstants.listPageSize;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _saving = false;
  String? _error;

  String? get businessId => _businessId;
  String get currencyCode => _currencyCode;
  List<Payment> get allPayments => _payments;
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get isSaving => _saving;
  String? get error => _error;

  List<Payment> forInvoice(String invoiceId) {
    final list = _payments.where((payment) => payment.invoiceId == invoiceId).toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
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
      _payments = const [];
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
        _payments = value;
        _hasMore = value.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Payment watch failed', error, stack);
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load payments.';
        notifyListeners();
      },
    );
  }

  Future<Payment> record({
    required Invoice invoice,
    required int amountMinor,
    required PaymentMethod method,
    required DateTime paidAt,
    String notes = '',
  }) async {
    if (!invoice.canRecordPayment) {
      throw const AppException(AppStrings.cannotRecordPayment, debugCode: 'payment-locked');
    }
    if (amountMinor <= 0) {
      throw const AppException(AppStrings.amountMustBePositive, debugCode: 'payment-amount');
    }
    if (amountMinor > invoice.outstanding.minorUnits) {
      throw const AppException(AppStrings.paymentExceedsOutstanding, debugCode: 'payment-overpay');
    }
    _saving = true;
    notifyListeners();
    try {
      final payment = await _repository.record(
        invoice: invoice,
        amountMinor: amountMinor,
        method: method,
        paidAt: paidAt,
        notes: notes,
      );
      _payments = [payment, ..._payments.where((item) => item.id != payment.id)];
      await _notifyPayment(payment);
      return payment;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> delete(Payment payment) async {
    _saving = true;
    notifyListeners();
    try {
      await _repository.delete(payment);
      _payments = _payments.where((item) => item.id != payment.id).toList();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> _notifyPayment(Payment payment) async {
    final notifications = _notifications;
    if (notifications == null) return;
    try {
      await notifications.upsert(AppNotification.paymentReceived(payment));
    } catch (error, stack) {
      AppLogger.error('Payment received notification failed', error, stack);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
