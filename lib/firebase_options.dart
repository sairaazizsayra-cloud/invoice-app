import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:invoice_pro/firebase/firebase_env.dart';

/// FlutterFire options for Android, iOS, macOS, web, and Windows.
///
/// Development options come from Firebase project `invoice-app-c8170`.
/// Production stays off until a second project is linked and
/// [productionConfigured] is set to true.
///
/// Do not put Firebase Admin credentials in this file. These are client options.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const bool developmentConfigured = true;
  static const bool productionConfigured = false;

  static bool get isConfigured =>
      FirebaseAppEnvironment.isProduction ? productionConfigured : developmentConfigured;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError(FirebaseAppEnvironment.missingConfigMessage);
    }
    if (kIsWeb) {
      return webDevelopment;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseAppEnvironment.isProduction ? androidProduction : androidDevelopment;
      case TargetPlatform.iOS:
        return iosDevelopment;
      case TargetPlatform.macOS:
        return macosDevelopment;
      case TargetPlatform.windows:
        return windowsDevelopment;
      default:
        throw UnsupportedError(
          'InvoicePro is configured for Android, iOS, macOS, web, and Windows.',
        );
    }
  }

  static const FirebaseOptions androidDevelopment = FirebaseOptions(
    apiKey: 'AIzaSyB8_WIqSWA9VoRID8tvqNlz96z3dTetbQs',
    appId: '1:406681420992:android:bb974874c9a91adc7b1925',
    messagingSenderId: '406681420992',
    projectId: 'invoice-app-c8170',
    storageBucket: 'invoice-app-c8170.firebasestorage.app',
  );

  static const FirebaseOptions iosDevelopment = FirebaseOptions(
    apiKey: 'AIzaSyB4RPdJbo-t04SitzFs0ukL21xeqcoBZV0',
    appId: '1:406681420992:ios:fd61c33956ac2a207b1925',
    messagingSenderId: '406681420992',
    projectId: 'invoice-app-c8170',
    storageBucket: 'invoice-app-c8170.firebasestorage.app',
    iosBundleId: 'com.invoicepro.invoicePro',
  );

  /// macOS shares the iOS Firebase app (same bundle id).
  static const FirebaseOptions macosDevelopment = iosDevelopment;

  static const FirebaseOptions webDevelopment = FirebaseOptions(
    apiKey: 'AIzaSyCm3DdqttTPFCUmF_mHSrmbfp6jQpnipYs',
    appId: '1:406681420992:web:4426e50e1e9d50a77b1925',
    messagingSenderId: '406681420992',
    projectId: 'invoice-app-c8170',
    authDomain: 'invoice-app-c8170.firebaseapp.com',
    storageBucket: 'invoice-app-c8170.firebasestorage.app',
    measurementId: 'G-7H5FFMKXLZ',
  );

  /// FlutterFire Windows uses the web client options.
  static const FirebaseOptions windowsDevelopment = webDevelopment;

  static const FirebaseOptions androidProduction = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
  );
}
