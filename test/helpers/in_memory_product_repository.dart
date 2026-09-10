import 'dart:async';

import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/repositories/product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository({
    List<Product>? products,
    List<ProductCategory>? categories,
    List<InvoiceRecord>? invoices,
  }) : _products = [...?products],
       _categories = [...?categories],
       _invoices = [...?invoices],
       _nextProduct = (products?.length ?? 0) + 1,
       _nextCategory = (categories?.length ?? 0) + 1;

  final List<Product> _products;
  final List<ProductCategory> _categories;
  final List<InvoiceRecord> _invoices;
  final StreamController<List<Product>> _productController = StreamController<List<Product>>.broadcast();
  final StreamController<List<ProductCategory>> _categoryController =
      StreamController<List<ProductCategory>>.broadcast();
  int _nextProduct;
  int _nextCategory;

  static Product sample({
    String id = 'prd_1',
    String businessId = 'biz_1',
    String name = 'Rice 10kg',
    ProductKind kind = ProductKind.product,
    int priceMinor = 250000,
    int stockQuantity = 12,
    String categoryId = '',
    String categoryName = '',
    String sku = 'RICE-10',
  }) {
    return Product(
      id: id,
      businessId: businessId,
      name: name,
      sku: sku,
      kind: kind,
      priceMinor: priceMinor,
      stockQuantity: stockQuantity,
      categoryId: categoryId,
      categoryName: categoryName,
      trackStock: kind == ProductKind.product,
    );
  }

  @override
  String newProductId(String businessId) {
    final id = 'prd_$_nextProduct';
    _nextProduct += 1;
    return id;
  }

  @override
  String newCategoryId(String businessId) {
    final id = 'cat_$_nextCategory';
    _nextCategory += 1;
    return id;
  }

  List<Product> _productsFor(String businessId) {
    final list = _products.where((item) => item.businessId == businessId).toList()
      ..sort((a, b) => a.nameLower.compareTo(b.nameLower));
    return list;
  }

  List<ProductCategory> _categoriesFor(String businessId) {
    final list = _categories.where((item) => item.businessId == businessId).toList()
      ..sort((a, b) => a.nameLower.compareTo(b.nameLower));
    return list;
  }

  @override
  Stream<List<Product>> watchProducts(
    String businessId, {
    int limit = AppConstants.listPageSize,
  }) async* {
    List<Product> page() => _productsFor(businessId).take(limit).toList();
    yield page();
    yield* _productController.stream.map((_) => page());
  }

  @override
  Stream<List<ProductCategory>> watchCategories(String businessId) async* {
    yield _categoriesFor(businessId);
    yield* _categoryController.stream.map((_) => _categoriesFor(businessId));
  }

  @override
  Future<Product> createProduct(Product product) async {
    _products.add(product);
    _productController.add(List<Product>.from(_products));
    return product;
  }

  @override
  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      _productController.add(List<Product>.from(_products));
    }
  }

  @override
  Future<void> deleteProduct(Product product) async {
    for (final invoice in _invoices) {
      if (invoice.lines.any((line) => line.productId == product.id)) {
        throw const AppException(AppStrings.cannotDeleteProduct, debugCode: 'product-has-invoices');
      }
    }
    _products.removeWhere((item) => item.id == product.id);
    _productController.add(List<Product>.from(_products));
  }

  @override
  Future<ProductCategory> createCategory(ProductCategory category) async {
    _categories.add(category);
    _categoryController.add(List<ProductCategory>.from(_categories));
    return category;
  }

  @override
  Future<void> deleteCategory(ProductCategory category) async {
    _categories.removeWhere((item) => item.id == category.id);
    _categoryController.add(List<ProductCategory>.from(_categories));
  }

  void dispose() {
    unawaited(_productController.close());
    unawaited(_categoryController.close());
  }
}
