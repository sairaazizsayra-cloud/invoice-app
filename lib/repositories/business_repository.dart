import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/business.dart';

abstract class BusinessRepository {
  String newId();

  Stream<Business?> watch(String businessId);

  Future<Business?> fetch(String businessId);

  Future<Business> createForOwner({
    required AppUser owner,
    String? businessId,
  });

  Future<void> update(Business business);

  Future<Business> ensureForOwner(AppUser owner);
}
