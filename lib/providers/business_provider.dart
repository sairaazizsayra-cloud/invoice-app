import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/repositories/business_repository.dart';
import 'package:invoice_pro/repositories/user_repository.dart';
import 'package:invoice_pro/services/storage_service.dart';

class BusinessProvider extends ChangeNotifier {
  BusinessProvider({
    required BusinessRepository businessRepository,
    required UserRepository userRepository,
    required StorageService storageService,
  }) : _businesses = businessRepository,
       _users = userRepository,
       _storage = storageService;

  final BusinessRepository _businesses;
  final UserRepository _users;
  final StorageService _storage;

  StreamSubscription<Business?>? _subscription;
  String? _businessId;
  Business? _business;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  Business? get business => _business;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get error => _error;

  void bindOwner(AppUser? owner) {
    final nextId = owner?.businessId;
    if (nextId == _businessId && _subscription != null) return;
    unawaited(_resubscribe(nextId, owner));
  }

  Future<void> _resubscribe(String? businessId, AppUser? owner) async {
    await _subscription?.cancel();
    _subscription = null;
    _businessId = businessId;
    _business = null;
    _error = null;

    if (businessId == null || businessId.isEmpty) {
      if (owner != null) {
        _loading = true;
        notifyListeners();
        try {
          final created = await _businesses.ensureForOwner(owner);
          _businessId = created.id;
          _business = created;
          _subscribe(created.id);
        } on AppException catch (error) {
          _error = error.userMessage;
        } catch (error, stack) {
          AppLogger.error('Business ensure failed', error, stack);
        } finally {
          _loading = false;
          notifyListeners();
        }
      } else {
        notifyListeners();
      }
      return;
    }

    _subscribe(businessId);
  }

  void _subscribe(String businessId) {
    _loading = true;
    notifyListeners();
    _subscription = _businesses.watch(businessId).listen(
      (value) {
        _business = value;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Business watch failed', error, stack);
        _loading = false;
        _error = 'Could not load business profile.';
        notifyListeners();
      },
    );
  }

  Future<void> save(Business updated) async {
    _saving = true;
    notifyListeners();
    try {
      await _businesses.update(updated);
      await _users.updateOwnerDetails(
        uid: updated.ownerId,
        name: updated.ownerName,
        businessName: updated.name,
        phone: updated.phone,
      );
      _business = updated;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String> uploadLogo({required String businessId, required Uint8List bytes}) {
    return _storage.uploadBusinessLogo(businessId: businessId, bytes: bytes);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
