import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/invoice.dart';

abstract class InvoiceRepository {
  String newId(String businessId);

  Stream<List<Invoice>> watchAll(
    String businessId, {
    int limit = AppConstants.listPageSize,
  });

  Future<Invoice?> fetch({required String businessId, required String invoiceId});

  Future<Invoice> create({required Invoice invoice, required Business business});

  Future<void> update(Invoice invoice);

  Future<void> delete(Invoice invoice);
}
