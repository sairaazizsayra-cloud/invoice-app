import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/storage_keys.dart';
import 'package:invoice_pro/services/local_storage_service.dart';

class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider(this._storage) {
    _isCompleted = _storage.getBool(StorageKeys.onboardingCompleted);
  }

  final LocalStorageService _storage;
  late bool _isCompleted;

  bool get isCompleted => _isCompleted;

  Future<void> complete() async {
    if (_isCompleted) return;
    _isCompleted = true;
    notifyListeners();
    await _storage.setBool(StorageKeys.onboardingCompleted, true);
  }

  Future<void> reset() async {
    if (!_isCompleted) return;
    _isCompleted = false;
    notifyListeners();
    await _storage.setBool(StorageKeys.onboardingCompleted, false);
  }
}
