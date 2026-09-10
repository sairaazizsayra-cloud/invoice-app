import 'dart:async';

import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/invoice_number.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/repositories/invoice_repository.dart';

class InMemoryInvoiceRepository implements InvoiceRepository {
  InMemoryInvoiceRepository({
    List<Invoice>? invoices,
    int? nextSequence,
  }) : _invoices = [...?invoices],
       _next = nextSequence ?? ((invoices?.length ?? 0) + 1),
       _nextId = (invoices?.length ?? 0) + 1;

  final List<Invoice> _invoices;
  final StreamController<List<Invoice>> _controller = StreamController<List<Invoice>>.broadcast();
  int _next;
  int _nextId;

  static Invoice sample({
    String id = 'inv_1',
    String businessId = 'biz_1',
    String invoiceNumber = 'INV-00001',
    int invoiceSequence = 1,
    String customerId = 'cus_1',
    String customerName = 'Ali Store',
    InvoiceStatus status = InvoiceStatus.unpaid,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceLine>? items,
  }) {
    final line = items ??
        [
          InvoiceLine.calculated(
            productId: 'prd_1',
            name: 'Rice 10kg',
            quantity: 1,
            unitPriceMinor: 250000,
          ),
        ];
    return Invoice(
      id: id,
      businessId: businessId,
      invoiceNumber: invoiceNumber,
      invoiceSequence: invoiceSequence,
      customerId: customerId,
      customerName: customerName,
      businessName: 'Khan Traders',
      status: status,
      issueDate: issueDate ?? DateTime(2026, 9, 1),
      dueDate: dueDate ?? DateTime(2026, 9, 8),
    ).withItems(line);
  }

  @override
  String newId(String businessId) {
    final id = 'inv_$_nextId';
    _nextId += 1;
    return id;
  }

  List<Invoice> _forBusiness(String businessId) {
    final list = _invoices.where((invoice) => invoice.businessId == businessId).toList()
      ..sort((a, b) => b.invoiceNumber.compareTo(a.invoiceNumber));
    return list;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<Invoice>.from(_invoices));
    }
  }

  @override
  Stream<List<Invoice>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    List<Invoice> page() => _forBusiness(businessId).take(limit).toList();
    yield page();
    yield* _controller.stream.map((_) => page());
  }

  @override
  Future<Invoice?> fetch({required String businessId, required String invoiceId}) async {
    for (final invoice in _invoices) {
      if (invoice.businessId == businessId && invoice.id == invoiceId) return invoice;
    }
    return null;
  }

  @override
  Future<Invoice> create({required Invoice invoice, required Business business}) async {
    final sequence = _next;
    _next += 1;
    final numbered = invoice.copyWith(
      invoiceNumber: InvoiceNumberFormatter.format(number: sequence, prefix: business.invoicePrefix),
      invoiceSequence: sequence,
    );
    _invoices.add(numbered);
    _emit();
    return numbered;
  }

  @override
  Future<void> update(Invoice invoice) async {
    final index = _invoices.indexWhere((item) => item.id == invoice.id);
    if (index >= 0) {
      _invoices[index] = invoice;
      _emit();
    }
  }

  @override
  Future<void> delete(Invoice invoice) async {
    if (!invoice.canDelete) {
      throw const AppException(AppStrings.cannotDeleteInvoice, debugCode: 'invoice-locked');
    }
    _invoices.removeWhere((item) => item.id == invoice.id);
    _emit();
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
