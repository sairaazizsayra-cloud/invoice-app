/// Configurable product identity and defaults.
///
/// Change [appName] together with native labels when rebranding.
/// Android applicationId: `com.invoicepro.invoice_pro`
/// iOS/macOS bundle id: `com.invoicepro.invoicePro`
class AppConstants {
  AppConstants._();

  static const String appName = 'Invoice App';
  static const String appTagline = 'Billing Manager';
  static const String appFullName = '$appName – $appTagline';
  static const String appIconAsset = 'assets/images/app_icon.png';

  static const String defaultCurrencyCode = 'PKR';
  static const String defaultCurrencySymbol = 'Rs ';
  static const int moneyDecimalDigits = 2;

  static const String defaultInvoicePrefix = 'INV-';
  static const int defaultInvoiceStartNumber = 1;
  static const int invoiceNumberPadding = 5;

  static const int defaultTaxPercentMinor = 0;
  static const int defaultReorderLevel = 5;
  static const String defaultProductUnit = 'pcs';
  static const List<String> productUnits = [
    'pcs',
    'kg',
    'g',
    'litre',
    'hour',
    'day',
    'box',
    'pack',
  ];

  static const Duration splashMinDisplay = Duration(milliseconds: 1600);

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);

  static const int maxImageUploadBytes = 2 * 1024 * 1024;
  static const int maxPdfUploadBytes = 8 * 1024 * 1024;

  /// Initial (and incremental) page size for Firestore list watches.
  static const int listPageSize = 40;

  /// Cap for date-scoped dashboard invoice/payment/expense queries.
  static const int dashboardQueryLimit = 200;

  /// Cap for the in-app notification inbox stream.
  static const int notificationInboxLimit = 100;

  /// Gallery picks are resized/compressed before upload.
  static const double imagePickMaxDimension = 1024;
  static const int imagePickQuality = 75;

  static const String notificationChannelId = 'invoicepro_alerts';
  static const String notificationChannelName = 'Invoice alerts';
}
