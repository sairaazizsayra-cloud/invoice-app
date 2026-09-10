import 'package:invoice_pro/core/constants/app_constants.dart';

class AppStrings {
  AppStrings._();

  static const String appName = AppConstants.appName;
  static const String appTagline = AppConstants.appTagline;

  static const String splashTagline = 'Invoices, payments, and books — in one place.';

  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingGetStarted = 'Get started';

  static const String onboardingTitle1 = 'Professional invoices';
  static const String onboardingBody1 =
      'Create branded invoices, track due dates, and share PDFs with your customers.';

  static const String onboardingTitle2 = 'Customers and products';
  static const String onboardingBody2 =
      'Keep customer details, product catalogues, and stock in one business workspace.';

  static const String onboardingTitle3 = 'Clear financial picture';
  static const String onboardingBody3 =
      'See revenue, expenses, and outstanding balances with reports you can actually use.';

  static const String navDashboard = 'Dashboard';
  static const String navInvoices = 'Invoices';
  static const String navCustomers = 'Customers';
  static const String navProducts = 'Products';
  static const String navProfile = 'Profile';

  static const String dashboardGreeting = 'Welcome to InvoicePro';
  static const String dashboardSubtitle = 'Your business overview for the selected period.';
  static const String totalRevenue = 'Total revenue';
  static const String totalInvoices = 'Total invoices';
  static const String paidInvoices = 'Paid';
  static const String unpaidInvoices = 'Unpaid';
  static const String overdueInvoices = 'Overdue';
  static const String totalCustomers = 'Customers';
  static const String totalProducts = 'Products';
  static const String totalExpenses = 'Expenses';
  static const String netProfit = 'Net profit';
  static const String recentInvoices = 'Recent invoices';
  static const String recentPayments = 'Recent payments';
  static const String topProducts = 'Top products';
  static const String topCustomers = 'Top customers';

  static const String filterToday = 'Today';
  static const String filterThisWeek = 'This week';
  static const String filterThisMonth = 'This month';
  static const String filterThisYear = 'This year';
  static const String filterCustom = 'Custom';

  static const String emptyInvoicesTitle = 'No invoices yet';
  static const String emptyInvoicesBody =
      'Invoices you create will show up here with their payment status.';
  static const String emptyCustomersTitle = 'No customers yet';
  static const String emptyCustomersBody =
      'Add customers to bill them faster and track outstanding balances.';
  static const String emptyProductsTitle = 'No products yet';
  static const String emptyProductsBody =
      'Add products and services to reuse them on invoices.';
  static const String emptyPaymentsTitle = 'No payments yet';
  static const String emptyPaymentsBody = 'Recorded payments will appear in this list.';
  static const String emptyRecentInvoicesTitle = 'No invoices in this period';
  static const String emptyRecentInvoicesBody =
      'Invoices issued in the selected dates will show here.';
  static const String emptyGenericTitle = 'Nothing to show';
  static const String emptyGenericBody = 'There is no data for this view yet.';

  static const String invoicesTitle = 'Invoices';
  static const String customersTitle = 'Customers';
  static const String productsTitle = 'Products';
  static const String profileTitle = 'Profile';
  static const String searchHint = 'Search';

  static const String appearance = 'Appearance';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String about = 'About';
  static const String version = 'Version';
  static const String replayOnboarding = 'Replay onboarding';
  static const String replayOnboardingBody = 'Show the introduction screens again on next launch.';

  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Sign in to manage invoices for your business.';
  static const String loginAction = 'Sign in';
  static const String loginNoAccount = 'New to InvoicePro?';
  static const String loginCreateAccount = 'Create an account';
  static const String forgotPasswordLink = 'Forgot password?';

  static const String registerTitle = 'Create your account';
  static const String registerSubtitle = 'Register your business to start billing customers.';
  static const String registerAction = 'Create account';
  static const String registerHaveAccount = 'Already have an account?';
  static const String registerSignIn = 'Sign in';
  static const String fullNameLabel = 'Full name';
  static const String businessNameLabel = 'Business name';
  static const String emailLabel = 'Email';
  static const String phoneLabel = 'Phone';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm password';

  static const String forgotPasswordTitle = 'Reset password';
  static const String forgotPasswordSubtitle =
      'Enter the email for your account. We will send a reset link if it exists.';
  static const String forgotPasswordAction = 'Send reset email';
  static const String forgotPasswordSent = 'Password reset email sent. Check your inbox.';

  static const String verifyTitle = 'Verify your email';
  static const String verifySubtitle =
      'We sent a verification link to your email. Open it, then continue.';
  static const String verifyResend = 'Resend email';
  static const String verifyContinue = 'I have verified';
  static const String verifyResent = 'Verification email sent.';
  static const String verifyStillPending = 'Email is not verified yet. Check your inbox and try again.';

  static const String logout = 'Sign out';
  static const String logoutConfirmTitle = 'Sign out?';
  static const String logoutConfirmBody = 'You will need to sign in again to access this business.';
  static const String accountSection = 'Account';

  static const String authInvalidEmail = 'Enter a valid email address.';
  static const String authWrongPassword = 'Incorrect email or password.';
  static const String authUserNotFound = 'No account was found for this email.';
  static const String authUserDisabled = 'This account has been disabled.';
  static const String authNetworkError = 'Network error. Check your connection and try again.';
  static const String authEmailInUse = 'An account already exists for this email.';
  static const String authWeakPassword = 'Choose a stronger password.';
  static const String authTooManyRequests = 'Too many attempts. Wait a moment and try again.';
  static const String authOperationNotAllowed = 'Email sign-in is not enabled for this Firebase project.';
  static const String authRequiresRecentLogin = 'Please sign in again to continue.';
  static const String authEmailUnverified = 'Verify your email before accessing the app.';
  static const String authFirebaseNotConfigured =
      'Firebase is not configured yet. Run flutterfire configure and enable Email/Password authentication.';
  static const String authPermissionDenied =
      'Could not save your account. Please try again in a moment.';
  static const String authFirestoreNotReady =
      'Account storage is still being set up. Please try again in a moment.';
  static const String authAppCheckBlocked =
      'App verification failed. Restart the app and try again.';
  static const String authUnauthorizedDomain =
      'This site is not allowed to create accounts. Use the Android app or localhost.';

  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String close = 'Close';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String ok = 'OK';

  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Enter a valid email address.';
  static const String invalidPhone = 'Enter a valid Pakistani mobile number.';
  static const String passwordTooShort = 'Password must be at least 8 characters.';
  static const String passwordNeedsLetter = 'Password must include a letter.';
  static const String passwordNeedsNumber = 'Password must include a number.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';
  static const String invalidAmount = 'Enter a valid amount.';
  static const String amountMustBePositive = 'Amount must be greater than zero.';
  static const String nameTooShort = 'Enter at least 2 characters.';
  static const String invalidWebsite = 'Enter a valid website, such as https://business.pk';
  static const String invalidTaxPercent = 'Enter a tax rate between 0 and 100.';
  static const String invalidInvoicePrefix = 'Use 2–10 letters, numbers, or dashes.';
  static const String businessSaved = 'Business profile saved.';
  static const String logoUpdated = 'Logo updated.';
  static const String logoUploadFailed = 'Could not upload the logo. Try a smaller JPG or PNG.';
  static const String pickLogo = 'Change logo';
  static const String businessProfileTitle = 'Business profile';
  static const String businessProfileSubtitle = 'These details appear on invoices and the dashboard.';
  static const String ownerNameLabel = 'Owner name';
  static const String addressLabel = 'Address';
  static const String cityLabel = 'City';
  static const String websiteLabel = 'Website';
  static const String taxNumberLabel = 'Tax number';
  static const String currencyLabel = 'Currency';
  static const String defaultTaxLabel = 'Default tax (%)';
  static const String invoicePrefixLabel = 'Invoice prefix';
  static const String paymentInstructionsLabel = 'Payment instructions';
  static const String termsLabel = 'Terms & Conditions';
  static const String monthlySales = 'Monthly sales';
  static const String revenueChart = 'Revenue';
  static const String emptyTopCustomersTitle = 'No customer sales yet';
  static const String emptyTopCustomersBody = 'Top customers will appear after you record invoices.';
  static const String emptyTopProductsTitle = 'No product sales yet';
  static const String emptyTopProductsBody = 'Top products will appear after invoices include line items.';
  static const String emptyChartTitle = 'No activity in this period';
  static const String emptyChartBody = 'Sales and revenue will plot here when invoices and payments exist.';
  static const String customRangeTitle = 'Custom range';
  static const String businessMissing = 'Your business workspace is still being prepared.';
  static const String dashboardLiveSubtitle = 'Figures are calculated from your Firebase data for the selected dates.';

  static const String somethingWentWrong = 'Something went wrong. Please try again.';
  static const String pageNotFound = 'This page is not available.';
  static const String goHome = 'Go to dashboard';

  static const String loading = 'Loading…';

  static const String addCustomer = 'Add customer';
  static const String editCustomer = 'Edit customer';
  static const String customerDetails = 'Customer details';
  static const String customerNameLabel = 'Customer name';
  static const String companyLabel = 'Company';
  static const String notesLabel = 'Notes';
  static const String searchCustomersHint = 'Search customers';
  static const String filterAll = 'All';
  static const String filterOutstanding = 'Outstanding';
  static const String filterHasEmail = 'Has email';
  static const String customerSaved = 'Customer saved.';
  static const String customerDeleted = 'Customer deleted.';
  static const String deleteCustomerTitle = 'Delete this customer?';
  static const String deleteCustomerBody =
      'This removes the customer from your workspace. Invoices they already have are not deleted.';
  static const String cannotDeleteCustomer =
      'This customer has invoices. Delete or reassign those invoices first.';
  static const String totalPurchases = 'Total purchases';
  static const String outstandingBalance = 'Outstanding';
  static const String invoiceHistory = 'Invoice history';
  static const String paymentHistory = 'Payment history';
  static const String emptyCustomerInvoicesTitle = 'No invoices for this customer';
  static const String emptyCustomerInvoicesBody =
      'Invoices you create for this customer will appear here.';
  static const String emptyCustomerPaymentsTitle = 'No payments for this customer';
  static const String emptyCustomerPaymentsBody =
      'Recorded payments from this customer will appear here.';
  static const String noCustomerResultsTitle = 'No matching customers';
  static const String noCustomerResultsBody = 'Try a different name, phone, city, or filter.';

  static const String addProduct = 'Add item';
  static const String editProduct = 'Edit item';
  static const String productDetails = 'Item details';
  static const String productNameLabel = 'Name';
  static const String skuLabel = 'SKU';
  static const String descriptionLabel = 'Description';
  static const String categoryLabel = 'Category';
  static const String priceLabel = 'Price';
  static const String costPriceLabel = 'Cost price';
  static const String stockLabel = 'Stock';
  static const String reorderLabel = 'Reorder at';
  static const String unitLabel = 'Unit';
  static const String kindProduct = 'Product';
  static const String kindService = 'Service';
  static const String searchProductsHint = 'Search products and services';
  static const String filterProducts = 'Products';
  static const String filterServices = 'Services';
  static const String filterLowStock = 'Low stock';
  static const String filterAllCategories = 'All categories';
  static const String addCategory = 'Add category';
  static const String categoryNameLabel = 'Category name';
  static const String productSaved = 'Item saved.';
  static const String productDeleted = 'Item deleted.';
  static const String categorySaved = 'Category added.';
  static const String deleteProductTitle = 'Delete this item?';
  static const String deleteProductBody =
      'This removes the product or service from your catalogue. Existing invoices are not changed.';
  static const String cannotDeleteProduct =
      'This item is used on invoices. Remove it from those invoices first.';
  static const String cannotDeleteCategory =
      'This category still has products. Move or delete those items first.';
  static const String categoryExists = 'A category with this name already exists.';
  static const String skuInUse = 'This SKU is already used by another item.';
  static const String invalidSku = 'Use 2–24 letters, numbers, or dashes.';
  static const String invalidStock = 'Enter a whole number that is zero or more.';
  static const String pickProductImage = 'Change photo';
  static const String productImageFailed = 'Could not upload the photo. Try a smaller JPG or PNG.';
  static const String noProductResultsTitle = 'No matching items';
  static const String noProductResultsBody = 'Try a different name, SKU, category, or filter.';
  static const String lowStockLabel = 'Low stock';
  static const String inStockLabel = 'In stock';
  static const String notTrackedLabel = 'Stock not tracked';

  static const String addInvoice = 'Create invoice';
  static const String editInvoice = 'Edit invoice';
  static const String invoiceDetails = 'Invoice details';
  static const String searchInvoicesHint = 'Search invoices';
  static const String filterDraft = 'Draft';
  static const String filterUnpaid = 'Unpaid';
  static const String filterPaid = 'Paid';
  static const String filterOverdue = 'Overdue';
  static const String filterCancelled = 'Cancelled';
  static const String invoiceSaved = 'Invoice saved.';
  static const String invoiceIssued = 'Invoice issued.';
  static const String invoiceDeleted = 'Invoice deleted.';
  static const String invoiceCancelled = 'Invoice cancelled.';
  static const String invoiceDuplicated = 'Invoice duplicated.';
  static const String invoiceMarkedSent = 'Invoice marked as sent.';
  static const String deleteInvoiceTitle = 'Delete this invoice?';
  static const String deleteInvoiceBody =
      'This permanently removes the invoice. Issued invoices that are not drafts should be cancelled instead.';
  static const String cancelInvoiceTitle = 'Cancel this invoice?';
  static const String cancelInvoiceBody =
      'Cancelled invoices stay in your records but are excluded from outstanding balances.';
  static const String cannotDeleteInvoice = 'Only draft or cancelled invoices can be deleted.';
  static const String cannotEditInvoice = 'This invoice can no longer be edited.';
  static const String cannotCancelInvoice = 'This invoice cannot be cancelled.';
  static const String invoiceNeedsCustomer = 'Select a customer before saving this invoice.';
  static const String invoiceNeedsItems = 'Add at least one item before issuing this invoice.';
  static const String invoiceNeedsTotal = 'Invoice total must be greater than zero.';
  static const String dueBeforeIssue = 'Due date cannot be before the invoice date.';
  static const String selectCustomer = 'Select customer';
  static const String addInvoiceCustomer = 'Add customer';
  static const String invoiceNumberLabel = 'Invoice number';
  static const String invoiceDateLabel = 'Invoice date';
  static const String dueDateLabel = 'Due date';
  static const String paymentTermsLabel = 'Payment terms';
  static const String addInvoiceItem = 'Add item';
  static const String editInvoiceItem = 'Edit item';
  static const String invoiceItems = 'Items';
  static const String quantityLabel = 'Quantity';
  static const String unitPriceLabel = 'Unit price';
  static const String discountLabel = 'Discount';
  static const String taxLabel = 'Tax (%)';
  static const String lineTotalLabel = 'Line total';
  static const String subtotalLabel = 'Subtotal';
  static const String grandTotalLabel = 'Grand total';
  static const String amountDueLabel = 'Amount due';
  static const String amountPaidLabel = 'Amount paid';
  static const String saveDraft = 'Save draft';
  static const String issueInvoice = 'Issue invoice';
  static const String markSent = 'Mark as sent';
  static const String duplicateInvoice = 'Duplicate';
  static const String cancelInvoiceAction = 'Cancel invoice';
  static const String invoiceNotesLabel = 'Notes';
  static const String noInvoiceResultsTitle = 'No matching invoices';
  static const String noInvoiceResultsBody = 'Try a different number, customer, or filter.';
  static const String emptyInvoiceItemsTitle = 'No items yet';
  static const String emptyInvoiceItemsBody = 'Add products or services to calculate the invoice total.';
  static const String selectProduct = 'Select a product or service';
  static const String customItem = 'Custom item';
  static const String invalidQuantity = 'Enter a whole number of 1 or more.';
  static const String quantityMustBePositive = 'Quantity must be at least 1.';
  static const String discountExceedsSubtotal = 'Discount cannot exceed the line subtotal.';
  static const String invoiceFromCustomer = 'Create invoice';
  static const String noCustomersForInvoiceTitle = 'No customers yet';
  static const String noCustomersForInvoiceBody = 'Add a customer first so you can bill them.';
  static const String noProductsForInvoiceTitle = 'No catalogue items yet';
  static const String noProductsForInvoiceBody = 'Add a product or enter a custom line item.';

  static const String invoicePdfSection = 'PDF';
  static const String previewPdf = 'Preview';
  static const String generatePdf = 'Generate PDF';
  static const String sharePdf = 'Share';
  static const String printPdf = 'Print';
  static const String savePdf = 'Save';
  static const String pdfPreviewTitle = 'Invoice PDF';
  static const String pdfSaved = 'Invoice PDF saved on this device.';
  static const String pdfGenerated = 'Invoice PDF generated.';
  static const String pdfUploaded = 'Invoice PDF saved and uploaded.';
  static const String pdfFailed = 'Could not create the PDF. Please try again.';
  static const String pdfSaveFailed = 'Could not save the PDF on this device.';
  static const String pdfUploadFailed = 'Could not upload the PDF. It was still saved on this device.';

  static const String recordPayment = 'Record payment';
  static const String markPaid = 'Mark as paid';
  static const String paymentAmountLabel = 'Amount received';
  static const String paymentMethodLabel = 'Payment method';
  static const String paymentDateLabel = 'Payment date';
  static const String paymentNotesLabel = 'Payment notes';
  static const String remainingBalanceLabel = 'Remaining balance';
  static const String paymentRecorded = 'Payment recorded.';
  static const String invoiceMarkedPaid = 'Invoice marked as paid.';
  static const String paymentDeleted = 'Payment removed.';
  static const String cannotRecordPayment = 'Payments can only be recorded on issued, unpaid invoices.';
  static const String paymentExceedsOutstanding = 'Amount cannot be more than the remaining balance.';
  static const String cannotDeletePayment = 'This payment could not be removed.';
  static const String deletePaymentTitle = 'Remove this payment?';
  static const String deletePaymentBody =
      'The invoice balance and status will be recalculated from the remaining payments.';
  static const String emptyInvoicePaymentsTitle = 'No payments on this invoice';
  static const String emptyInvoicePaymentsBody = 'Record a payment to reduce the remaining balance.';
  static const String invoiceMissing = 'This invoice could not be found.';

  static const String expensesTitle = 'Expenses';
  static const String expensesSubtitle = 'Rent, salaries, and other business costs.';
  static const String addExpense = 'Add expense';
  static const String editExpense = 'Edit expense';
  static const String expenseDetails = 'Expense details';
  static const String expenseTitleLabel = 'Expense title';
  static const String expenseCategoryLabel = 'Category';
  static const String expenseAmountLabel = 'Amount';
  static const String expenseDateLabel = 'Date';
  static const String expenseDescriptionLabel = 'Description';
  static const String searchExpensesHint = 'Search expenses';
  static const String expenseSaved = 'Expense saved.';
  static const String expenseDeleted = 'Expense deleted.';
  static const String deleteExpenseTitle = 'Delete this expense?';
  static const String deleteExpenseBody = 'This removes the expense from your books and dashboard totals.';
  static const String emptyExpensesTitle = 'No expenses yet';
  static const String emptyExpensesBody = 'Add rent, salaries, and other costs so net profit is accurate.';
  static const String noExpenseResultsTitle = 'No matching expenses';
  static const String noExpenseResultsBody = 'Try a different title, category, or filter.';

  static const String reportsTitle = 'Reports';
  static const String reportsSubtitle = 'Sales, invoices, customers, products, and expenses.';
  static const String salesReportTitle = 'Sales report';
  static const String salesReportSubtitle = 'Daily, weekly, monthly, and yearly revenue.';
  static const String invoiceReportTitle = 'Invoice report';
  static const String invoiceReportSubtitle = 'Paid, unpaid, overdue, and cancelled invoices.';
  static const String customerReportTitle = 'Customer report';
  static const String customerReportSubtitle = 'Billed amounts and outstanding balances.';
  static const String productReportTitle = 'Product report';
  static const String productReportSubtitle = 'Quantities sold and line totals.';
  static const String expenseReportTitle = 'Expense report';
  static const String expenseReportSubtitle = 'Costs by category for the selected dates.';
  static const String reportBilled = 'Billed';
  static const String reportCount = 'Count';
  static const String reportPeriod = 'Period';
  static const String reportStatusLabel = 'Status';
  static const String emptyReportTitle = 'No activity in this period';
  static const String emptyReportBody = 'Invoices, payments, or expenses in these dates will appear here.';
  static const String reportPdfSaved = 'Report PDF saved on this device.';
  static const String reportPdfPreviewTitle = 'Report PDF';

  static const String notificationsTitle = 'Notifications';
  static const String notificationsSubtitle = 'Invoice created, payments, and overdue alerts.';
  static const String notificationInvoiceCreatedTitle = 'Invoice created';
  static const String notificationPaymentReceivedTitle = 'Payment received';
  static const String notificationInvoiceOverdueTitle = 'Invoice overdue';
  static const String emptyNotificationsTitle = 'No notifications yet';
  static const String emptyNotificationsBody =
      'You will be notified when an invoice is issued, a payment is recorded, or an invoice becomes overdue.';
  static const String markAllRead = 'Mark all read';
  static const String notificationChannelDescription =
      'Invoice created, payments, and overdue reminders.';
  static const String loadMore = 'Load more';
  static const String loadingMore = 'Loading more…';

  static String notificationOverdueCount(int count) {
    if (count == 1) return '1 invoice is overdue.';
    return '$count invoices are overdue.';
  }
}
