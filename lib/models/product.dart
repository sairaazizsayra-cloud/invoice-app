import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/app_user.dart';

enum ProductKind { product, service }

extension ProductKindX on ProductKind {
  String get storage => name;

  String get label => this == ProductKind.service ? 'Service' : 'Product';

  static ProductKind fromStorage(String? raw) {
    if (raw == ProductKind.service.name) return ProductKind.service;
    return ProductKind.product;
  }
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.businessId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nameLower => name.trim().toLowerCase();

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'nameLower': nameLower,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ProductCategory.fromMap(String id, Map<String, dynamic> data) {
    return ProductCategory(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    this.sku = '',
    this.description = '',
    this.kind = ProductKind.product,
    this.categoryId = '',
    this.categoryName = '',
    this.priceMinor = 0,
    this.costMinor = 0,
    this.taxPercentMinor = AppConstants.defaultTaxPercentMinor,
    this.stockQuantity = 0,
    this.reorderLevel = AppConstants.defaultReorderLevel,
    this.trackStock = true,
    this.unit = AppConstants.defaultProductUnit,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String sku;
  final String description;
  final ProductKind kind;
  final String categoryId;
  final String categoryName;
  final int priceMinor;
  final int costMinor;
  final int taxPercentMinor;
  final int stockQuantity;
  final int reorderLevel;
  final bool trackStock;
  final String unit;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nameLower => name.trim().toLowerCase();
  String get skuLower => sku.trim().toLowerCase();
  bool get isService => kind == ProductKind.service;
  bool get isProduct => kind == ProductKind.product;

  bool get isLowStock {
    if (!trackStock || isService) return false;
    return stockQuantity <= reorderLevel;
  }

  Money price({String currencyCode = AppConstants.defaultCurrencyCode}) {
    return Money.fromMinorUnits(priceMinor, currencyCode: currencyCode);
  }

  Money cost({String currencyCode = AppConstants.defaultCurrencyCode}) {
    return Money.fromMinorUnits(costMinor, currencyCode: currencyCode);
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    return parts.first.substring(0, 1).toUpperCase();
  }

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        sku.toLowerCase().contains(needle) ||
        description.toLowerCase().contains(needle) ||
        categoryName.toLowerCase().contains(needle) ||
        unit.toLowerCase().contains(needle);
  }

  Product copyWith({
    String? name,
    String? sku,
    String? description,
    ProductKind? kind,
    String? categoryId,
    String? categoryName,
    int? priceMinor,
    int? costMinor,
    int? taxPercentMinor,
    int? stockQuantity,
    int? reorderLevel,
    bool? trackStock,
    String? unit,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return Product(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      priceMinor: priceMinor ?? this.priceMinor,
      costMinor: costMinor ?? this.costMinor,
      taxPercentMinor: taxPercentMinor ?? this.taxPercentMinor,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      trackStock: trackStock ?? this.trackStock,
      unit: unit ?? this.unit,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'nameLower': nameLower,
      'sku': sku,
      'skuLower': skuLower,
      'description': description,
      'kind': kind.storage,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'priceMinor': priceMinor,
      'costMinor': costMinor,
      'taxPercentMinor': taxPercentMinor,
      'stockQuantity': stockQuantity,
      'reorderLevel': reorderLevel,
      'trackStock': trackStock,
      'unit': unit,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'sku': sku,
      'skuLower': skuLower,
      'description': description,
      'kind': kind.storage,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'priceMinor': priceMinor,
      'costMinor': costMinor,
      'taxPercentMinor': taxPercentMinor,
      'stockQuantity': stockQuantity,
      'reorderLevel': reorderLevel,
      'trackStock': trackStock,
      'unit': unit,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String? ?? id,
      businessId: data['businessId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      sku: data['sku'] as String? ?? '',
      description: data['description'] as String? ?? '',
      kind: ProductKindX.fromStorage(data['kind'] as String?),
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      priceMinor: (data['priceMinor'] as num?)?.toInt() ?? 0,
      costMinor: (data['costMinor'] as num?)?.toInt() ?? 0,
      taxPercentMinor:
          (data['taxPercentMinor'] as num?)?.toInt() ?? AppConstants.defaultTaxPercentMinor,
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      reorderLevel: (data['reorderLevel'] as num?)?.toInt() ?? AppConstants.defaultReorderLevel,
      trackStock: data['trackStock'] as bool? ?? true,
      unit: data['unit'] as String? ?? AppConstants.defaultProductUnit,
      imageUrl: data['imageUrl'] as String?,
      createdAt: AppUser.dateTimeFrom(data['createdAt']),
      updatedAt: AppUser.dateTimeFrom(data['updatedAt']),
    );
  }
}
