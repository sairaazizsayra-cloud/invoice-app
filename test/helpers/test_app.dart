import 'package:invoice_pro/app.dart';
import 'package:invoice_pro/repositories/auth_repository.dart';
import 'package:invoice_pro/repositories/business_repository.dart';
import 'package:invoice_pro/repositories/customer_repository.dart';
import 'package:invoice_pro/repositories/dashboard_repository.dart';
import 'package:invoice_pro/repositories/expense_repository.dart';
import 'package:invoice_pro/repositories/invoice_repository.dart';
import 'package:invoice_pro/repositories/notification_repository.dart';
import 'package:invoice_pro/repositories/payment_repository.dart';
import 'package:invoice_pro/repositories/product_repository.dart';
import 'package:invoice_pro/repositories/user_repository.dart';
import 'package:invoice_pro/services/local_storage_service.dart';
import 'package:invoice_pro/services/storage_service.dart';

import 'in_memory_auth_repository.dart';
import 'in_memory_business_repository.dart';
import 'in_memory_customer_repository.dart';
import 'in_memory_expense_repository.dart';
import 'in_memory_invoice_repository.dart';
import 'in_memory_notification_repository.dart';
import 'in_memory_payment_repository.dart';
import 'in_memory_product_repository.dart';

InvoiceProApp buildTestApp({
  required LocalStorageService storage,
  AuthRepository? authRepository,
  BusinessRepository? businessRepository,
  DashboardRepository? dashboardRepository,
  CustomerRepository? customerRepository,
  ProductRepository? productRepository,
  InvoiceRepository? invoiceRepository,
  PaymentRepository? paymentRepository,
  ExpenseRepository? expenseRepository,
  NotificationRepository? notificationRepository,
  String? initialLocation,
}) {
  final invoices = invoiceRepository ?? InMemoryInvoiceRepository();
  return InvoiceProApp(
    storage: storage,
    authRepository: authRepository ?? InMemoryAuthRepository(),
    businessRepository: businessRepository ?? InMemoryBusinessRepository(),
    dashboardRepository: dashboardRepository ?? InMemoryDashboardRepository(),
    customerRepository: customerRepository ?? InMemoryCustomerRepository(),
    productRepository: productRepository ?? InMemoryProductRepository(),
    invoiceRepository: invoices,
    paymentRepository: paymentRepository ?? InMemoryPaymentRepository(invoices: invoices),
    expenseRepository: expenseRepository ?? InMemoryExpenseRepository(),
    notificationRepository: notificationRepository ?? InMemoryNotificationRepository(),
    userRepository: UserRepository(),
    storageService: StorageService(),
    initialLocation: initialLocation,
  );
}
