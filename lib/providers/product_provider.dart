import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/repositories/product_repository.dart';
import 'package:invoice_pro/services/storage_service.dart';

enum ProductListFilter { all, products, services, lowStock }

class ProductProvider extends ChangeNotifier {
  ProductProvider({
    required ProductRepository productRepository,
    required StorageService storageService,
  }) : _productsRepo = productRepository,
       _storage = storageService;

  final ProductRepository _productsRepo;
  final StorageService _storage;

  StreamSubscription<List<Product>>? _productSub;
  StreamSubscription<List<ProductCategory>>? _categorySub;
  String? _businessId;
  String _currencyCode = AppConstants.defaultCurrencyCode;
  List<Product> _products = const [];
  List<ProductCategory> _categories = const [];
  String _query = '';
  ProductListFilter _filter = ProductListFilter.all;
  String? _categoryId;
  int _pageSize = AppConstants.listPageSize;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _saving = false;
  String? _error;

  String? get businessId => _businessId;
  String get currencyCode => _currencyCode;
  List<Product> get allProducts => _products;
  List<ProductCategory> get categories => _categories;
  String get query => _query;
  ProductListFilter get filter => _filter;
  String? get categoryId => _categoryId;
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get isSaving => _saving;
  String? get error => _error;

  List<Product> get visibleProducts {
    var list = _products;
    if (_query.trim().isNotEmpty) {
      list = list.where((product) => product.matches(_query)).toList();
    }
    switch (_filter) {
      case ProductListFilter.all:
        break;
      case ProductListFilter.products:
        list = list.where((product) => product.isProduct).toList();
      case ProductListFilter.services:
        list = list.where((product) => product.isService).toList();
      case ProductListFilter.lowStock:
        list = list.where((product) => product.isLowStock).toList();
    }
    if (_categoryId != null && _categoryId!.isNotEmpty) {
      list = list.where((product) => product.categoryId == _categoryId).toList();
    }
    return list;
  }

  Product? byId(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  ProductCategory? categoryById(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  void bind({String? businessId, String currencyCode = AppConstants.defaultCurrencyCode}) {
    _currencyCode = currencyCode;
    if (businessId == _businessId && _productSub != null) return;
    unawaited(_resubscribe(businessId, resetPageSize: true));
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || _businessId == null || _businessId!.isEmpty) return;
    _loadingMore = true;
    notifyListeners();
    _pageSize += AppConstants.listPageSize;
    await _resubscribe(_businessId, resetPageSize: false, showFullLoading: false);
  }

  Future<void> _resubscribe(
    String? businessId, {
    required bool resetPageSize,
    bool showFullLoading = true,
  }) async {
    await _productSub?.cancel();
    await _categorySub?.cancel();
    _productSub = null;
    _categorySub = null;
    _businessId = businessId;
    if (resetPageSize) {
      _pageSize = AppConstants.listPageSize;
      _products = const [];
      _categories = const [];
    }
    _error = null;

    if (businessId == null || businessId.isEmpty) {
      _loading = false;
      _loadingMore = false;
      _hasMore = false;
      notifyListeners();
      return;
    }

    if (showFullLoading) {
      _loading = true;
      notifyListeners();
    }
    _productSub = _productsRepo.watchProducts(businessId, limit: _pageSize).listen(
      (value) {
        _products = value;
        _hasMore = value.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Product watch failed', error, stack);
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load products.';
        notifyListeners();
      },
    );
    _categorySub = _productsRepo.watchCategories(businessId).listen(
      (value) {
        _categories = value;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('Category watch failed', error, stack);
      },
    );
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setFilter(ProductListFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  void setCategoryId(String? value) {
    if (value == _categoryId) return;
    _categoryId = value;
    notifyListeners();
  }

  String nextProductId() {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return _productsRepo.newProductId(businessId);
  }

  Future<Product> save(Product draft) async {
    _assertUniqueSku(draft);
    _saving = true;
    notifyListeners();
    try {
      final existing = byId(draft.id);
      if (existing == null) {
        await _productsRepo.createProduct(draft);
      } else {
        await _productsRepo.updateProduct(draft);
      }
      return draft;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> delete(Product product) async {
    _saving = true;
    notifyListeners();
    try {
      await _productsRepo.deleteProduct(product);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<ProductCategory> addCategory(String name) async {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) {
      throw const AppException(AppStrings.businessMissing, debugCode: 'no-business');
    }
    final trimmed = name.trim();
    if (trimmed.length < 2) {
      throw const AppException(AppStrings.nameTooShort, debugCode: 'category-name');
    }
    final duplicate = _categories.any((item) => item.nameLower == trimmed.toLowerCase());
    if (duplicate) {
      throw const AppException(AppStrings.categoryExists, debugCode: 'category-exists');
    }
    final category = ProductCategory(
      id: _productsRepo.newCategoryId(businessId),
      businessId: businessId,
      name: trimmed,
    );
    _saving = true;
    notifyListeners();
    try {
      return await _productsRepo.createCategory(category);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(ProductCategory category) async {
    final inUse = _products.any((product) => product.categoryId == category.id);
    if (inUse) {
      throw const AppException(AppStrings.cannotDeleteCategory, debugCode: 'category-in-use');
    }
    _saving = true;
    notifyListeners();
    try {
      await _productsRepo.deleteCategory(category);
      if (_categoryId == category.id) {
        _categoryId = null;
      }
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String> uploadImage({required String productId, required Uint8List bytes}) {
    final businessId = _businessId;
    if (businessId == null || businessId.isEmpty) {
      throw const AppException(AppStrings.businessMissing, debugCode: 'no-business');
    }
    return _storage.uploadProductImage(businessId: businessId, productId: productId, bytes: bytes);
  }

  void _assertUniqueSku(Product draft) {
    final sku = draft.skuLower;
    if (sku.isEmpty) return;
    final clash = _products.any((product) => product.id != draft.id && product.skuLower == sku);
    if (clash) {
      throw const AppException(AppStrings.skuInUse, debugCode: 'sku-duplicate');
    }
  }

  @override
  void dispose() {
    unawaited(_productSub?.cancel());
    unawaited(_categorySub?.cancel());
    super.dispose();
  }
}
