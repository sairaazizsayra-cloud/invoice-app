import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/repositories/business_repository.dart';
import 'package:invoice_pro/repositories/dashboard_repository.dart';
import 'package:invoice_pro/repositories/firebase_business_repository.dart';
import 'package:invoice_pro/repositories/firebase_dashboard_repository.dart';
import 'package:invoice_pro/services/storage_service.dart';

BusinessRepository createBusinessRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredBusinessRepository();
  }
  return FirebaseBusinessRepository();
}

DashboardRepository createDashboardRepository() {
  if (!FirebaseBootstrap.initialized) {
    return const UnconfiguredDashboardRepository();
  }
  return FirebaseDashboardRepository();
}

StorageService createStorageService() => StorageService();

class UnconfiguredBusinessRepository implements BusinessRepository {
  UnconfiguredBusinessRepository();

  Business? _business;

  static const _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  String newId() => 'unconfigured';

  @override
  Stream<Business?> watch(String businessId) async* {
    yield _business;
  }

  @override
  Future<Business?> fetch(String businessId) async => _business;

  @override
  Future<Business> createForOwner({required AppUser owner, String? businessId}) async {
    _business = Business.fromOwner(id: businessId ?? newId(), owner: owner);
    return _business!;
  }

  @override
  Future<void> update(Business business) async {
    throw _notConfigured;
  }

  @override
  Future<Business> ensureForOwner(AppUser owner) {
    return createForOwner(owner: owner, businessId: owner.businessId);
  }
}

class UnconfiguredDashboardRepository implements DashboardRepository {
  const UnconfiguredDashboardRepository();

  @override
  Future<DashboardSnapshot> load({
    required Business business,
    required DateRange range,
    required DateTime now,
  }) async {
    return DashboardSnapshot.empty(currencyCode: business.currencyCode);
  }
}
