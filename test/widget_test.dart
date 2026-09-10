import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/storage_keys.dart';
import 'package:invoice_pro/models/app_notification.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/customers/customers_screen.dart';
import 'package:invoice_pro/screens/expenses/expense_form_screen.dart';
import 'package:invoice_pro/screens/expenses/expenses_screen.dart';
import 'package:invoice_pro/screens/invoices/invoice_detail_screen.dart';
import 'package:invoice_pro/screens/invoices/invoice_form_screen.dart';
import 'package:invoice_pro/screens/invoices/invoices_screen.dart';
import 'package:invoice_pro/screens/invoices/payment_form_screen.dart';
import 'package:invoice_pro/screens/notifications/notifications_screen.dart';
import 'package:invoice_pro/screens/products/products_screen.dart';
import 'package:invoice_pro/screens/profile/profile_screen.dart';
import 'package:invoice_pro/screens/reports/report_detail_screen.dart';
import 'package:invoice_pro/screens/reports/reports_screen.dart';
import 'package:invoice_pro/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/in_memory_auth_repository.dart';
import 'helpers/in_memory_customer_repository.dart';
import 'helpers/in_memory_expense_repository.dart';
import 'helpers/in_memory_invoice_repository.dart';
import 'helpers/in_memory_notification_repository.dart';
import 'helpers/in_memory_payment_repository.dart';
import 'helpers/in_memory_product_repository.dart';
import 'helpers/test_app.dart';

Future<LocalStorageService> _storage({bool onboardingCompleted = false}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.onboardingCompleted: onboardingCompleted,
  });
  final prefs = await SharedPreferences.getInstance();
  return LocalStorageService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows onboarding after splash when it is not completed', (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(buildTestApp(storage: storage));
    expect(find.text(AppStrings.appName), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
  });

  testWidgets('opens login after onboarding when the user is signed out', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(storage: storage, initialLocation: AppRoutes.login),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.loginAction), findsOneWidget);
  });

  testWidgets('login validates empty credentials without calling a fake backend', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(storage: storage, initialLocation: AppRoutes.login),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.loginAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.requiredField), findsWidgets);
  });

  testWidgets('opens a live dashboard with zeros when collections are empty', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.dashboard,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Ayesha Khan'), findsOneWidget);
    expect(find.text('Khan Traders'), findsOneWidget);
    expect(find.text(AppStrings.totalRevenue), findsOneWidget);
    expect(find.text('Rs 0.00'), findsWidgets);
    expect(find.text(AppStrings.emptyChartTitle), findsWidgets);
    expect(find.text(AppStrings.emptyRecentInvoicesTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyPaymentsTitle), findsOneWidget);
  });

  testWidgets('unverified users are sent to email verification', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.unverifiedSession()),
        initialLocation: AppRoutes.dashboard,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.verifyTitle), findsOneWidget);
    expect(find.text(AppStrings.verifyContinue), findsOneWidget);
  });

  testWidgets('bottom navigation reaches invoices, customers, products, and profile', (
    tester,
  ) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.dashboard,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.navInvoices));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.emptyInvoicesTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navCustomers));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.emptyCustomersTitle), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CustomersScreen), matching: find.byType(FloatingActionButton)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.navProducts));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.emptyProductsTitle), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ProductsScreen), matching: find.byType(FloatingActionButton)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.navProfile));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.businessProfileTitle), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ProfileScreen), matching: find.text(AppStrings.expensesTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ProfileScreen), matching: find.text(AppStrings.reportsTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ProfileScreen), matching: find.text(AppStrings.notificationsTitle)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.logout), findsOneWidget);
  });

  testWidgets('business profile opens from the profile screen', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.businessProfileTitle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.businessNameLabel), findsOneWidget);
    expect(find.text(AppStrings.pickLogo), findsOneWidget);
    expect(find.text(AppStrings.save), findsOneWidget);
  });

  testWidgets('creates a customer and shows them on the list', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.customers,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyCustomersTitle), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(CustomersScreen), matching: find.byType(FloatingActionButton)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.customerNameLabel), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ali Store');
    await tester.ensureVisible(find.text(AppStrings.save));
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('Ali Store'), findsWidgets);
    expect(find.text(AppStrings.emptyCustomersTitle), findsNothing);
  });

  testWidgets('opens customer details and filters the list by search', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        customerRepository: InMemoryCustomerRepository(
          customers: [
            InMemoryCustomerRepository.sample(),
            InMemoryCustomerRepository.sample(
              id: 'cus_2',
              name: 'Fatima Mart',
              email: 'fatima@mart.pk',
              phone: '03009998877',
              city: 'Karachi',
            ),
          ],
        ),
        initialLocation: AppRoutes.customers,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ali Store'), findsOneWidget);
    expect(find.text('Fatima Mart'), findsOneWidget);

    await tester.tap(find.text('Fatima Mart'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.customerDetails), findsOneWidget);
    expect(find.text(AppStrings.totalPurchases), findsOneWidget);
    expect(find.text(AppStrings.emptyCustomerInvoicesTitle), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: find.byType(CustomersScreen), matching: find.byType(TextField)),
      'Karachi',
    );
    await tester.pumpAndSettle();
    expect(find.text('Fatima Mart'), findsOneWidget);
    expect(find.text('Ali Store'), findsNothing);
  });

  testWidgets('creates a product and shows it on the catalogue', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.products,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyProductsTitle), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(ProductsScreen), matching: find.byType(FloatingActionButton)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productNameLabel), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Rice 10kg');
    await tester.enterText(find.byType(TextFormField).at(3), '2500');
    await tester.ensureVisible(find.text(AppStrings.save));
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('Rice 10kg'), findsOneWidget);
    expect(find.text(AppStrings.emptyProductsTitle), findsNothing);
  });

  testWidgets('opens product details and filters the catalogue by search', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        productRepository: InMemoryProductRepository(
          products: [
            InMemoryProductRepository.sample(),
            InMemoryProductRepository.sample(
              id: 'prd_2',
              name: 'Delivery',
              kind: ProductKind.service,
              priceMinor: 50000,
              stockQuantity: 0,
              sku: 'DEL-1',
            ),
          ],
        ),
        initialLocation: AppRoutes.products,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rice 10kg'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.productDetails), findsOneWidget);
    expect(find.text(AppStrings.kindService), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: find.byType(ProductsScreen), matching: find.byType(TextField)),
      'Rice',
    );
    await tester.pumpAndSettle();
    expect(find.text('Rice 10kg'), findsOneWidget);
    expect(find.text('Delivery'), findsNothing);
  });

  testWidgets('creates an invoice from a customer and product', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        customerRepository: InMemoryCustomerRepository(customers: [InMemoryCustomerRepository.sample()]),
        productRepository: InMemoryProductRepository(products: [InMemoryProductRepository.sample()]),
        initialLocation: AppRoutes.invoices,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyInvoicesTitle), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(InvoicesScreen), matching: find.byType(FloatingActionButton)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.selectCustomer), findsWidgets);
    await tester.tap(find.text(AppStrings.selectCustomer).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ali Store').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.descendant(of: find.byType(InvoiceFormScreen), matching: find.text(AppStrings.addInvoiceItem)),
    );
    await tester.tap(
      find.descendant(of: find.byType(InvoiceFormScreen), matching: find.text(AppStrings.addInvoiceItem)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rice 10kg').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.issueInvoice));
    await tester.tap(find.text(AppStrings.issueInvoice));
    await tester.pumpAndSettle();

    expect(find.text('INV-00001'), findsOneWidget);
    expect(find.text(AppStrings.emptyInvoicesTitle), findsNothing);
  });

  testWidgets('opens invoice details and filters the list by search', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        invoiceRepository: InMemoryInvoiceRepository(
          invoices: [
            InMemoryInvoiceRepository.sample(),
            InMemoryInvoiceRepository.sample(
              id: 'inv_2',
              invoiceNumber: 'INV-00002',
              invoiceSequence: 2,
              customerName: 'Fatima Mart',
              customerId: 'cus_2',
            ),
          ],
          nextSequence: 3,
        ),
        initialLocation: AppRoutes.invoices,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INV-00001'), findsOneWidget);
    expect(find.text('INV-00002'), findsOneWidget);

    await tester.tap(find.text('INV-00002'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.invoiceDetails), findsOneWidget);
    expect(find.text('Fatima Mart'), findsWidgets);
    expect(find.text(AppStrings.grandTotalLabel), findsOneWidget);
    expect(find.text(AppStrings.amountPaidLabel), findsOneWidget);
    expect(find.text(AppStrings.recordPayment), findsOneWidget);
    expect(find.text(AppStrings.markPaid), findsOneWidget);
    expect(find.text(AppStrings.previewPdf), findsOneWidget);
    expect(find.text(AppStrings.generatePdf), findsOneWidget);
    expect(find.text(AppStrings.sharePdf), findsOneWidget);
    expect(find.text(AppStrings.printPdf), findsOneWidget);
    expect(find.text(AppStrings.savePdf), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: find.byType(InvoicesScreen), matching: find.byType(TextField)),
      'Fatima',
    );
    await tester.pumpAndSettle();
    expect(find.text('INV-00002'), findsOneWidget);
    expect(find.text('INV-00001'), findsNothing);
  });

  testWidgets('records a partial payment and updates remaining balance', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        invoiceRepository: InMemoryInvoiceRepository(
          invoices: [InMemoryInvoiceRepository.sample()],
        ),
        initialLocation: AppRoutes.invoices,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('INV-00001'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppStrings.recordPayment));
    await tester.tap(find.text(AppStrings.recordPayment));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentFormScreen), findsOneWidget);

    await tester.enterText(
      find.descendant(of: find.byType(PaymentFormScreen), matching: find.byType(TextFormField)).first,
      '1000.00',
    );
    final savePayment = find.descendant(
      of: find.byType(PaymentFormScreen),
      matching: find.widgetWithText(FilledButton, AppStrings.recordPayment),
    );
    await tester.ensureVisible(savePayment);
    await tester.tap(savePayment);
    await tester.pumpAndSettle();

    expect(find.byType(PaymentFormScreen), findsNothing);
    expect(find.text(InvoiceStatus.partiallyPaid.label), findsWidgets);
    expect(find.textContaining('1,000.00'), findsWidgets);
    expect(find.textContaining('1,500.00'), findsWidgets);
    expect(find.textContaining(PaymentMethod.cash.label), findsWidgets);
  });

  testWidgets('creates an expense and shows it on the list', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.expenses,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyExpensesTitle), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(ExpensesScreen), matching: find.byType(FloatingActionButton)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.expenseTitleLabel), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(ExpenseFormScreen),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'Shop rent');
    await tester.enterText(fields.at(1), '200.00');
    final saveExpense = find.descendant(
      of: find.byType(ExpenseFormScreen),
      matching: find.widgetWithText(FilledButton, AppStrings.save),
    );
    await tester.ensureVisible(saveExpense);
    await tester.tap(saveExpense);
    await tester.pumpAndSettle();

    expect(find.text('Shop rent'), findsOneWidget);
    expect(find.text(AppStrings.emptyExpensesTitle), findsNothing);
  });

  testWidgets('opens expense details and filters the list by search', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        expenseRepository: InMemoryExpenseRepository(
          expenses: [
            InMemoryExpenseRepository.sample(),
            InMemoryExpenseRepository.sample(
              id: 'exp_2',
              title: 'Fuel',
              category: ExpenseCategory.transport,
              amountMinor: 4500,
              date: DateTime(2026, 9, 2),
              description: 'Delivery van',
            ),
          ],
        ),
        initialLocation: AppRoutes.expenses,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shop rent'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);

    await tester.tap(find.text('Fuel'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.expenseDetails), findsOneWidget);
    expect(find.text(ExpenseCategory.transport.label), findsWidgets);
    expect(find.textContaining('45.00'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: find.byType(ExpensesScreen), matching: find.byType(TextField)),
      'Fuel',
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Fuel'), findsOneWidget);
    expect(find.text('Shop rent'), findsNothing);
  });

  testWidgets('opens expenses from profile', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(ProfileScreen), matching: find.text(AppStrings.expensesTitle)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpensesScreen), findsOneWidget);
    expect(find.text(AppStrings.emptyExpensesTitle), findsOneWidget);
  });

  testWidgets('opens reports from profile', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(ProfileScreen), matching: find.text(AppStrings.reportsTitle)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(find.text(AppStrings.salesReportTitle), findsOneWidget);
    expect(find.text(AppStrings.invoiceReportTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.salesReportTitle));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDetailScreen), findsOneWidget);
    expect(find.text(AppStrings.filterThisMonth), findsOneWidget);
    expect(find.text(AppStrings.totalRevenue), findsWidgets);
  });

  testWidgets('opens notifications from profile', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(ProfileScreen), matching: find.text(AppStrings.notificationsTitle)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text(AppStrings.emptyNotificationsTitle), findsOneWidget);
  });

  testWidgets('opens notifications from the dashboard bell', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.dashboard,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.notificationsTitle));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text(AppStrings.emptyNotificationsTitle), findsOneWidget);
  });

  testWidgets('opening a notification marks it read and shows the invoice', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    final invoice = InMemoryInvoiceRepository.sample();
    final invoices = InMemoryInvoiceRepository(invoices: [invoice]);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        invoiceRepository: invoices,
        notificationRepository: InMemoryNotificationRepository(
          notifications: [
            AppNotification.invoiceCreated(invoice).copyWith(createdAt: DateTime(2026, 9, 3)),
          ],
        ),
        initialLocation: AppRoutes.notifications,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notificationInvoiceCreatedTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyNotificationsTitle), findsNothing);

    await tester.tap(find.text(AppStrings.notificationInvoiceCreatedTitle));
    await tester.pumpAndSettle();

    expect(find.byType(InvoiceDetailScreen), findsOneWidget);
    expect(
      find.descendant(of: find.byType(InvoiceDetailScreen), matching: find.text('INV-00001')),
      findsOneWidget,
    );
  });

  testWidgets('sales report uses live invoices, payments, and expenses', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    final invoice = InMemoryInvoiceRepository.sample(
      status: InvoiceStatus.paid,
    ).copyWith(paidMinor: 250000);
    final invoices = InMemoryInvoiceRepository(invoices: [invoice]);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        invoiceRepository: invoices,
        paymentRepository: InMemoryPaymentRepository(
          invoices: invoices,
          payments: [InMemoryPaymentRepository.sample(invoice: invoice, amountMinor: 100000)],
        ),
        expenseRepository: InMemoryExpenseRepository(expenses: [InMemoryExpenseRepository.sample()]),
        initialLocation: AppRoutes.report(ReportKind.sales),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1,000.00'), findsWidgets);
    expect(find.textContaining('2,500.00'), findsWidgets);
    expect(find.textContaining('200.00'), findsWidgets);
    expect(find.textContaining('800.00'), findsWidgets);
  });

  testWidgets('invoice report lists invoices for the selected period', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        invoiceRepository: InMemoryInvoiceRepository(
          invoices: [InMemoryInvoiceRepository.sample(status: InvoiceStatus.unpaid)],
        ),
        initialLocation: AppRoutes.report(ReportKind.invoices),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INV-00001'), findsOneWidget);
    expect(find.text('Ali Store'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, AppStrings.paidInvoices));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.emptyReportTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, AppStrings.unpaidInvoices));
    await tester.pumpAndSettle();
    expect(find.text('INV-00001'), findsOneWidget);
  });

  testWidgets('theme option can be switched to dark', (tester) async {
    final storage = await _storage(onboardingCompleted: true);
    await tester.pumpWidget(
      buildTestApp(
        storage: storage,
        authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(AppStrings.themeDark),
      80,
      scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.themeDark));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });

  testWidgets('dashboard adapts layout for phone and tablet widths', (tester) async {
    final storage = await _storage(onboardingCompleted: true);

    Future<void> pumpAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: buildTestApp(
            storage: storage,
            authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
            initialLocation: AppRoutes.dashboard,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpAt(const Size(390, 844));
    expect(find.text(AppStrings.totalRevenue), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await pumpAt(const Size(900, 1200));
    expect(find.text(AppStrings.totalRevenue), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('invoices empty state is visible in light and dark themes', (tester) async {
    Future<void> pumpInvoices({required String themeMode}) async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.onboardingCompleted: true,
        StorageKeys.themeMode: themeMode,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      await tester.pumpWidget(
        buildTestApp(
          storage: storage,
          authRepository: InMemoryAuthRepository(session: InMemoryAuthRepository.verifiedSession()),
          initialLocation: AppRoutes.invoices,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.emptyInvoicesTitle), findsOneWidget);
    }

    await pumpInvoices(themeMode: 'light');
    await pumpInvoices(themeMode: 'dark');
  });
}
