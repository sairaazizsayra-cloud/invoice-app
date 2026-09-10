import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoice_pro/app.dart';
import 'package:invoice_pro/firebase/crash_reporting.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/repositories/user_repository.dart';
import 'package:invoice_pro/services/auth_service.dart';
import 'package:invoice_pro/services/business_service.dart';
import 'package:invoice_pro/services/customer_service.dart';
import 'package:invoice_pro/services/expense_service.dart';
import 'package:invoice_pro/services/invoice_service.dart';
import 'package:invoice_pro/services/local_storage_service.dart';
import 'package:invoice_pro/services/notification_service.dart';
import 'package:invoice_pro/services/payment_service.dart';
import 'package:invoice_pro/services/product_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      CrashReporting.recordFatal(details.exceptionAsString(), details.exception, details.stack),
    );
  };

  WidgetsBinding.instance.platformDispatcher.onError = (Object error, StackTrace stack) {
    unawaited(CrashReporting.recordFatal(error.toString(), error, stack));
    return true;
  };

  if (!kIsWeb) {
    Isolate.current.addErrorListener(
      RawReceivePort((dynamic pair) {
        final details = pair as List<dynamic>;
        final error = details.isEmpty ? 'isolate-error' : details.first;
        final rawStack = details.length > 1 ? details[1] : null;
        unawaited(
          CrashReporting.recordFatal(
            'Isolate error',
            error,
            rawStack is StackTrace ? rawStack : null,
          ),
        );
      }).sendPort,
    );
  }

  await FirebaseBootstrap.initialize();
  await CrashReporting.attach();
  final storage = await LocalStorageService.init();
  runApp(
    InvoiceProApp(
      storage: storage,
      authRepository: createAuthRepository(),
      businessRepository: createBusinessRepository(),
      dashboardRepository: createDashboardRepository(),
      customerRepository: createCustomerRepository(),
      productRepository: createProductRepository(),
      invoiceRepository: createInvoiceRepository(),
      paymentRepository: createPaymentRepository(),
      expenseRepository: createExpenseRepository(),
      notificationRepository: createNotificationRepository(),
      userRepository: UserRepository(),
      storageService: createStorageService(),
    ),
  );
}

