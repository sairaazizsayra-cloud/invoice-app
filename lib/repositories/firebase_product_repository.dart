import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/constants/firestore_paths.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/repositories/product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  FirebaseProductRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _products(String businessId) {
    return _firestore.collection(FirestorePaths.products(businessId));
  }

  CollectionReference<Map<String, dynamic>> _categories(String businessId) {
    return _firestore.collection(FirestorePaths.categories(businessId));
  }

  @override
  String newProductId(String businessId) => _products(businessId).doc().id;

  @override
  String newCategoryId(String businessId) => _categories(businessId).doc().id;

  @override
  Stream<List<Product>> watchProducts(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) {
    return _products(businessId).orderBy('nameLower').limit(limit).snapshots().map((snapshot) {
      return [for (final doc in snapshot.docs) Product.fromMap(doc.id, doc.data())];
    });
  }

  @override
  Stream<List<ProductCategory>> watchCategories(String businessId) {
    return _categories(businessId).orderBy('nameLower').snapshots().map((snapshot) {
      return [for (final doc in snapshot.docs) ProductCategory.fromMap(doc.id, doc.data())];
    });
  }

  @override
  Future<Product> createProduct(Product product) async {
    try {
      await _firestore.doc(FirestorePaths.product(product.businessId, product.id)).set(product.toCreateMap());
      return product;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Product create failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .doc(FirestorePaths.product(product.businessId, product.id))
          .update(product.toUpdateMap());
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Product update failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> deleteProduct(Product product) async {
    try {
      if (await _isUsedOnInvoice(product)) {
        throw const AppException(AppStrings.cannotDeleteProduct, debugCode: 'product-has-invoices');
      }
      await _firestore.doc(FirestorePaths.product(product.businessId, product.id)).delete();
    } on AppException {
      rethrow;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Product delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<ProductCategory> createCategory(ProductCategory category) async {
    try {
      await _firestore
          .doc(FirestorePaths.category(category.businessId, category.id))
          .set(category.toCreateMap());
      return category;
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Category create failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  @override
  Future<void> deleteCategory(ProductCategory category) async {
    try {
      await _firestore.doc(FirestorePaths.category(category.businessId, category.id)).delete();
    } on FirebaseException catch (error, stack) {
      AppLogger.error('Category delete failed', error, stack);
      throw AppException(AppStrings.somethingWentWrong, debugCode: error.code, cause: error);
    }
  }

  Future<bool> _isUsedOnInvoice(Product product) async {
    try {
      final byIndex = await _firestore
          .collection(FirestorePaths.invoices(product.businessId))
          .where('lineProductIds', arrayContains: product.id)
          .limit(1)
          .get();
      if (byIndex.docs.isNotEmpty) return true;

      // Fallback for invoices created before lineProductIds was denormalized.
      final snapshot = await _firestore
          .collection(FirestorePaths.invoices(product.businessId))
          .limit(AppConstants.dashboardQueryLimit)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawItems = data['items'] ?? data['lines'];
        if (rawItems is! List) continue;
        for (final item in rawItems) {
          if (item is Map && item['productId'] == product.id) return true;
        }
      }
      return false;
    } catch (error, stack) {
      AppLogger.error('Product invoice usage query failed', error, stack);
      return false;
    }
  }
}
