import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/product.dart';

abstract class ProductRepository {
  String newProductId(String businessId);

  String newCategoryId(String businessId);

  Stream<List<Product>> watchProducts(
    String businessId, {
    int limit = AppConstants.listPageSize,
  });

  Stream<List<ProductCategory>> watchCategories(String businessId);

  Future<Product> createProduct(Product product);

  Future<void> updateProduct(Product product);

  Future<void> deleteProduct(Product product);

  Future<ProductCategory> createCategory(ProductCategory category);

  Future<void> deleteCategory(ProductCategory category);
}
