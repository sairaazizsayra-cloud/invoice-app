import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/auth_exception.dart';
import 'package:invoice_pro/firebase/firebase_bootstrap.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/repositories/firebase_product_repository.dart';
import 'package:invoice_pro/repositories/product_repository.dart';

ProductRepository createProductRepository() {
  if (!FirebaseBootstrap.initialized) {
    return UnconfiguredProductRepository();
  }
  return FirebaseProductRepository();
}

class UnconfiguredProductRepository implements ProductRepository {
  static const _notConfigured = AuthException(
    AppStrings.authFirebaseNotConfigured,
    debugCode: 'firebase-unconfigured',
  );

  @override
  String newProductId(String businessId) => 'unconfigured';

  @override
  String newCategoryId(String businessId) => 'unconfigured-cat';

  @override
  Stream<List<Product>> watchProducts(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    yield const [];
  }

  @override
  Stream<List<ProductCategory>> watchCategories(String businessId) async* {
    yield const [];
  }

  @override
  Future<Product> createProduct(Product product) async => throw _notConfigured;

  @override
  Future<void> updateProduct(Product product) async => throw _notConfigured;

  @override
  Future<void> deleteProduct(Product product) async => throw _notConfigured;

  @override
  Future<ProductCategory> createCategory(ProductCategory category) async => throw _notConfigured;

  @override
  Future<void> deleteCategory(ProductCategory category) async => throw _notConfigured;
}
