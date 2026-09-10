/// Canonical Firestore path builders.
///
/// These are architecture-only in Phase 1 (no Firebase SDK). Later phases
/// must use these helpers so security rules and client queries stay aligned.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String businesses = 'businesses';

  static String user(String uid) => '$users/$uid';

  static String business(String businessId) => '$businesses/$businessId';

  static String customers(String businessId) => '${business(businessId)}/customers';

  static String customer(String businessId, String customerId) =>
      '${customers(businessId)}/$customerId';

  static String products(String businessId) => '${business(businessId)}/products';

  static String product(String businessId, String productId) =>
      '${products(businessId)}/$productId';

  static String invoices(String businessId) => '${business(businessId)}/invoices';

  static String invoice(String businessId, String invoiceId) =>
      '${invoices(businessId)}/$invoiceId';

  static String payments(String businessId) => '${business(businessId)}/payments';

  static String payment(String businessId, String paymentId) =>
      '${payments(businessId)}/$paymentId';

  static String expenses(String businessId) => '${business(businessId)}/expenses';

  static String expense(String businessId, String expenseId) =>
      '${expenses(businessId)}/$expenseId';

  static String categories(String businessId) => '${business(businessId)}/categories';

  static String category(String businessId, String categoryId) =>
      '${categories(businessId)}/$categoryId';

  static String notifications(String businessId) =>
      '${business(businessId)}/notifications';

  static String notification(String businessId, String notificationId) =>
      '${notifications(businessId)}/$notificationId';

  static String settings(String businessId) => '${business(businessId)}/settings';

  static String setting(String businessId, String settingId) =>
      '${settings(businessId)}/$settingId';

  static String reports(String businessId) => '${business(businessId)}/reports';

  static String report(String businessId, String reportId) =>
      '${reports(businessId)}/$reportId';
}

/// Firebase Storage object path builders. Uploads are wired in later phases.
class StoragePaths {
  StoragePaths._();

  static String userProfile(String uid) => 'users/$uid/profile.jpg';

  static String businessLogo(String businessId) => 'businesses/$businessId/logo.jpg';

  static String productImage(String businessId, String productId) =>
      'businesses/$businessId/products/$productId.jpg';

  static String invoiceDocument(String businessId, String invoiceId) =>
      'businesses/$businessId/invoices/$invoiceId.pdf';
}
