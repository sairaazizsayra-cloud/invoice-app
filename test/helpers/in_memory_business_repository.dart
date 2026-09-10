import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/repositories/business_repository.dart';
import 'package:invoice_pro/repositories/dashboard_repository.dart';

class InMemoryBusinessRepository implements BusinessRepository {
  InMemoryBusinessRepository({Business? business}) : _business = business ?? sampleBusiness();

  Business? _business;

  static Business sampleBusiness() {
    return const Business(
      id: 'biz_1',
      ownerId: 'user_1',
      name: 'Khan Traders',
      ownerName: 'Ayesha Khan',
      email: 'owner@business.pk',
      phone: '03001234567',
      city: 'Lahore',
      currencyCode: AppConstants.defaultCurrencyCode,
    );
  }

  @override
  String newId() => 'biz_1';

  @override
  Stream<Business?> watch(String businessId) async* {
    yield _business?.id == businessId ? _business : null;
  }

  @override
  Future<Business?> fetch(String businessId) async {
    return _business?.id == businessId ? _business : null;
  }

  @override
  Future<Business> createForOwner({required AppUser owner, String? businessId}) async {
    _business = Business.fromOwner(id: businessId ?? newId(), owner: owner);
    return _business!;
  }

  @override
  Future<void> update(Business business) async {
    _business = business;
  }

  @override
  Future<Business> ensureForOwner(AppUser owner) async {
    return _business ?? Business.fromOwner(id: owner.businessId ?? newId(), owner: owner);
  }
}

class InMemoryDashboardRepository implements DashboardRepository {
  InMemoryDashboardRepository({DashboardSnapshot? snapshot}) : _snapshot = snapshot;

  final DashboardSnapshot? _snapshot;

  @override
  Future<DashboardSnapshot> load({
    required Business business,
    required DateRange range,
    required DateTime now,
  }) async {
    return _snapshot ?? DashboardSnapshot.empty(currencyCode: business.currencyCode);
  }
}
