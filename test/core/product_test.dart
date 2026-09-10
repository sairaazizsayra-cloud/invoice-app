import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/product.dart';

void main() {
  group('Product', () {
    test('reads a Firestore-shaped map with integer money fields', () {
      final product = Product.fromMap('prd_1', {
        'businessId': 'biz_1',
        'name': 'Rice 10kg',
        'sku': 'RICE-10',
        'kind': 'product',
        'priceMinor': 250000,
        'costMinor': 200000,
        'taxPercentMinor': 1700,
        'stockQuantity': 4,
        'reorderLevel': 5,
        'trackStock': true,
        'unit': 'bag',
        'categoryName': 'Grocery',
      });

      expect(product.name, 'Rice 10kg');
      expect(product.priceMinor, 250000);
      expect(product.price().format(includeSymbol: false), '2,500.00');
      expect(product.isLowStock, isTrue);
      expect(product.matches('rice'), isTrue);
      expect(product.matches('grocery'), isTrue);
    });

    test('does not track stock for services', () {
      final service = Product.fromMap('prd_2', {
        'businessId': 'biz_1',
        'name': 'Delivery',
        'kind': 'service',
        'priceMinor': 50000,
        'stockQuantity': 0,
        'trackStock': false,
      });
      expect(service.isService, isTrue);
      expect(service.isLowStock, isFalse);
      expect(service.kind.label, 'Service');
    });
  });

  group('ProductCategory', () {
    test('normalizes a category name for ordering', () {
      final category = ProductCategory.fromMap('cat_1', {
        'businessId': 'biz_1',
        'name': 'Grocery',
      });
      expect(category.nameLower, 'grocery');
      expect(AppConstants.productUnits, contains('pcs'));
    });
  });
}
