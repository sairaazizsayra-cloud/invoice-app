import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/providers/expense_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/notification_provider.dart';
import 'package:invoice_pro/providers/onboarding_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:invoice_pro/providers/product_provider.dart';
import 'package:invoice_pro/providers/theme_provider.dart';
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
import 'package:invoice_pro/routes/app_router.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/services/local_storage_service.dart';
import 'package:invoice_pro/services/push_notification_service.dart';
import 'package:invoice_pro/services/storage_service.dart';
import 'package:provider/provider.dart';

class InvoiceProApp extends StatefulWidget {
  const InvoiceProApp({
    super.key,
    required this.storage,
    required this.authRepository,
    required this.businessRepository,
    required this.dashboardRepository,
    required this.customerRepository,
    required this.productRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.expenseRepository,
    required this.notificationRepository,
    required this.userRepository,
    required this.storageService,
    this.initialLocation,
  });

  final LocalStorageService storage;
  final AuthRepository authRepository;
  final BusinessRepository businessRepository;
  final DashboardRepository dashboardRepository;
  final CustomerRepository customerRepository;
  final ProductRepository productRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final ExpenseRepository expenseRepository;
  final NotificationRepository notificationRepository;
  final UserRepository userRepository;
  final StorageService storageService;
  final String? initialLocation;

  @override
  State<InvoiceProApp> createState() => _InvoiceProAppState();
}

class _InvoiceProAppState extends State<InvoiceProApp> {
  late final ThemeProvider _themeProvider;
  late final OnboardingProvider _onboardingProvider;
  late final AuthProvider _authProvider;
  late final BusinessProvider _businessProvider;
  late final CustomerProvider _customerProvider;
  late final ProductProvider _productProvider;
  late final InvoiceProvider _invoiceProvider;
  late final PaymentProvider _paymentProvider;
  late final ExpenseProvider _expenseProvider;
  late final NotificationProvider _notificationProvider;
  late final PushNotificationService _push;
  late final GoRouter _router;
  String? _pushUid;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider(widget.storage);
    _onboardingProvider = OnboardingProvider(widget.storage);
    _authProvider = AuthProvider(widget.authRepository);
    _businessProvider = BusinessProvider(
      businessRepository: widget.businessRepository,
      userRepository: widget.userRepository,
      storageService: widget.storageService,
    );
    _customerProvider = CustomerProvider(widget.customerRepository);
    _productProvider = ProductProvider(
      productRepository: widget.productRepository,
      storageService: widget.storageService,
    );
    _push = PushNotificationService(
      onOpenInvoice: (invoiceId) => _router.push(AppRoutes.invoiceDetail(invoiceId)),
    );
    _invoiceProvider = InvoiceProvider(
      widget.invoiceRepository,
      notifications: widget.notificationRepository,
    );
    _paymentProvider = PaymentProvider(
      widget.paymentRepository,
      notifications: widget.notificationRepository,
    );
    _expenseProvider = ExpenseProvider(widget.expenseRepository);
    _notificationProvider = NotificationProvider(widget.notificationRepository, push: _push);
    _authProvider.addListener(_syncBusiness);
    _businessProvider.addListener(_syncCatalog);
    _invoiceProvider.addListener(_scanOverdue);
    _syncBusiness();
    _syncCatalog();
    _router = AppRouter.create(
      onboardingProvider: _onboardingProvider,
      authProvider: _authProvider,
      initialLocation: widget.initialLocation ?? AppRoutes.splash,
    );
  }

  void _syncBusiness() {
    _businessProvider.bindOwner(_authProvider.profile);
    _syncPush();
  }

  void _syncPush() {
    final uid = _authProvider.profile?.uid;
    if (uid == null || uid.isEmpty) {
      _pushUid = null;
      unawaited(_push.dispose());
      return;
    }
    if (uid == _pushUid) return;
    _pushUid = uid;
    unawaited(_push.start(uid: uid, users: widget.userRepository));
  }

  void _syncCatalog() {
    final business = _businessProvider.business;
    _customerProvider.bind(
      businessId: business?.id,
      currencyCode: business?.currencyCode ?? AppConstants.defaultCurrencyCode,
    );
    _productProvider.bind(
      businessId: business?.id,
      currencyCode: business?.currencyCode ?? AppConstants.defaultCurrencyCode,
    );
    _invoiceProvider.bind(
      businessId: business?.id,
      currencyCode: business?.currencyCode ?? AppConstants.defaultCurrencyCode,
    );
    _paymentProvider.bind(
      businessId: business?.id,
      currencyCode: business?.currencyCode ?? AppConstants.defaultCurrencyCode,
    );
    _expenseProvider.bind(
      businessId: business?.id,
      currencyCode: business?.currencyCode ?? AppConstants.defaultCurrencyCode,
    );
    _notificationProvider.bind(businessId: business?.id);
  }

  void _scanOverdue() {
    unawaited(_notificationProvider.scanOverdue(_invoiceProvider.allInvoices));
  }

  @override
  void dispose() {
    _authProvider.removeListener(_syncBusiness);
    _businessProvider.removeListener(_syncCatalog);
    _invoiceProvider.removeListener(_scanOverdue);
    _router.dispose();
    unawaited(_push.dispose());
    _notificationProvider.dispose();
    _expenseProvider.dispose();
    _paymentProvider.dispose();
    _invoiceProvider.dispose();
    _productProvider.dispose();
    _customerProvider.dispose();
    _businessProvider.dispose();
    _authProvider.dispose();
    _onboardingProvider.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<OnboardingProvider>.value(value: _onboardingProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<BusinessProvider>.value(value: _businessProvider),
        ChangeNotifierProvider<CustomerProvider>.value(value: _customerProvider),
        ChangeNotifierProvider<ProductProvider>.value(value: _productProvider),
        ChangeNotifierProvider<InvoiceProvider>.value(value: _invoiceProvider),
        ChangeNotifierProvider<PaymentProvider>.value(value: _paymentProvider),
        ChangeNotifierProvider<ExpenseProvider>.value(value: _expenseProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: _notificationProvider),
        Provider<DashboardRepository>.value(value: widget.dashboardRepository),
        Provider<StorageService>.value(value: widget.storageService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            title: AppConstants.appFullName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
