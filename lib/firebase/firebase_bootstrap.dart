import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/core/utils/platform_capabilities.dart';
import 'package:invoice_pro/firebase/app_check_config.dart';
import 'package:invoice_pro/firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool initialized = false;

  static Future<void> initialize() async {
    if (initialized) return;
    if (!DefaultFirebaseOptions.isConfigured) {
      AppLogger.debug('Firebase client options are not configured yet.');
      return;
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    try {
      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      }
    } catch (error, stack) {
      AppLogger.error('Firestore settings failed', error, stack);
    }
    initialized = true;
    await _activateAppCheck();
  }

  static Future<void> _activateAppCheck() async {
    if (!PlatformCapabilities.appCheck) return;
    try {
      final debug = AppCheckConfig.useDebugProvider();
      await FirebaseAppCheck.instance.activate(
        providerWeb: debug ? WebDebugProvider(debugToken: AppCheckConfig.debugTokenOrNull) : null,
        providerAndroid: debug
            ? AndroidDebugProvider(debugToken: AppCheckConfig.debugTokenOrNull)
            : const AndroidPlayIntegrityProvider(),
        providerApple: debug
            ? AppleDebugProvider(debugToken: AppCheckConfig.debugTokenOrNull)
            : const AppleDeviceCheckProvider(),
      );
    } catch (error, stack) {
      AppLogger.error('App Check activate failed', error, stack);
    }
  }
}
