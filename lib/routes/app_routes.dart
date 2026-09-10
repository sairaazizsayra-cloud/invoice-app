import 'package:invoice_pro/models/report.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String invoiceNew = '/invoices/new';
  static const String customers = '/customers';
  static const String customerNew = '/customers/new';
  static const String products = '/products';
  static const String productNew = '/products/new';
  static const String profile = '/profile';
  static const String businessProfile = '/business-profile';
  static const String expenses = '/expenses';
  static const String expenseNew = '/expenses/new';
  static const String reports = '/reports';
  static const String notifications = '/notifications';

  static String customerDetail(String customerId) => '/customers/$customerId';

  static String customerEdit(String customerId) => '/customers/$customerId/edit';

  static String invoiceDetail(String invoiceId) => '/invoices/$invoiceId';

  static String invoiceEdit(String invoiceId) => '/invoices/$invoiceId/edit';

  static String invoicePdf(String invoiceId) => '/invoices/$invoiceId/pdf';

  static String invoicePay(String invoiceId, {bool settleInFull = false}) {
    final path = '/invoices/$invoiceId/pay';
    return settleInFull ? '$path?full=1' : path;
  }

  static String invoiceNewForCustomer(String customerId) => '/invoices/new?customerId=$customerId';

  static String productDetail(String productId) => '/products/$productId';

  static String productEdit(String productId) => '/products/$productId/edit';

  static String expenseDetail(String expenseId) => '/expenses/$expenseId';

  static String expenseEdit(String expenseId) => '/expenses/$expenseId/edit';

  static String report(ReportKind kind) => '/reports/${kind.path}';

  static String reportPdf(ReportKind kind) => '/reports/${kind.path}/pdf';

  static const Set<String> authLocations = {
    login,
    register,
    forgotPassword,
  };

  static const Set<String> publicLocations = {
    splash,
    onboarding,
    login,
    register,
    forgotPassword,
  };
}
