import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/utils/platform_capabilities.dart';
import 'package:invoice_pro/firebase_options.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('DefaultFirebaseOptions', () {
    test('exposes development options for every supported platform', () {
      expect(DefaultFirebaseOptions.isConfigured, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(DefaultFirebaseOptions.currentPlatform.appId, contains(':android:'));

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(DefaultFirebaseOptions.currentPlatform.iosBundleId, 'com.invoicepro.invoicePro');

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(DefaultFirebaseOptions.currentPlatform.appId, contains(':ios:'));

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(DefaultFirebaseOptions.currentPlatform.appId, contains(':web:'));
    });

    test('rejects unsupported desktop platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(() => DefaultFirebaseOptions.currentPlatform, throwsUnsupportedError);
    });
  });

  group('PlatformCapabilities', () {
    test('enables Crashlytics only on Android, iOS, and macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(PlatformCapabilities.crashlytics, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(PlatformCapabilities.crashlytics, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(PlatformCapabilities.crashlytics, isFalse);
      expect(PlatformCapabilities.pushMessaging, isFalse);
      expect(PlatformCapabilities.appCheck, isFalse);
    });
  });
}
