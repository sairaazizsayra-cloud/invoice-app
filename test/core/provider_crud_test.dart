import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:invoice_pro/providers/product_provider.dart';
import 'package:invoice_pro/services/storage_service.dart';

import '../helpers/in_memory_business_repository.dart';
import '../helpers/in_memory_customer_repository.dart';
import '../helpers/in_memory_invoice_repository.dart';
import '../helpers/in_memory_payment_repository.dart';
import '../helpers/in_memory_product_repository.dart';

void main() {
  group('CustomerProvider CRUD', () {
    test('create, update, and delete a customer', () async {
      final repo = InMemoryCustomerRepository();
      final customers = CustomerProvider(repo);
      addTearDown(customers.dispose);
      customers.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);

      final created = await customers.save(
        InMemoryCustomerRepository.sample(id: customers.nextId(), name: 'New Shop'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(customers.allCustomers.any((c) => c.id == created.id), isTrue);

      await customers.save(created.copyWith(phone: '03009998877'));
      await Future<void>.delayed(Duration.zero);
      expect(customers.byId(created.id)?.phone, '03009998877');

      await customers.delete(created);
      await Future<void>.delayed(Duration.zero);
      expect(customers.byId(created.id), isNull);
    });
  });

  group('ProductProvider CRUD', () {
    test('create, update, and delete a product', () async {
      final repo = InMemoryProductRepository();
      final products = ProductProvider(productRepository: repo, storageService: StorageService());
      addTearDown(products.dispose);
      products.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);

      final created = await products.save(
        InMemoryProductRepository.sample(id: products.nextProductId(), name: 'Sugar 5kg'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(products.allProducts.any((p) => p.id == created.id), isTrue);

      await products.save(created.copyWith(priceMinor: 300000));
      await Future<void>.delayed(Duration.zero);
      expect(products.byId(created.id)?.priceMinor, 300000);

      await products.delete(created);
      await Future<void>.delayed(Duration.zero);
      expect(products.byId(created.id), isNull);
    });
  });

  group('InvoiceProvider and payments', () {
    test('create, edit, delete draft and track payment status', () async {
      final invoicesRepo = InMemoryInvoiceRepository();
      final invoices = InvoiceProvider(invoicesRepo);
      final payments = PaymentProvider(InMemoryPaymentRepository(invoices: invoicesRepo));
      addTearDown(invoices.dispose);
      addTearDown(payments.dispose);

      invoices.bind(businessId: 'biz_1');
      payments.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);

      final business = InMemoryBusinessRepository.sampleBusiness();
      final draft = InMemoryInvoiceRepository.sample(
        id: invoices.nextId(),
        invoiceNumber: '',
        invoiceSequence: 0,
        status: InvoiceStatus.draft,
      );
      final created = await invoices.save(draft, business: business, asDraft: true);
      await Future<void>.delayed(Duration.zero);
      expect(created.isDraft, isTrue);

      final issued = await invoices.save(
        created.withItems(created.items).copyWith(status: InvoiceStatus.unpaid),
        business: business,
        asDraft: false,
      );
      await Future<void>.delayed(Duration.zero);
      expect(issued.status, InvoiceStatus.unpaid);
      expect(issued.total.minorUnits, greaterThan(0));

      final payment = await payments.record(
        invoice: issued,
        amountMinor: issued.total.minorUnits ~/ 2,
        method: PaymentMethod.cash,
        paidAt: DateTime(2026, 9, 3),
      );
      await Future<void>.delayed(Duration.zero);
      expect(payment.amountMinor, issued.total.minorUnits ~/ 2);

      final live = await invoicesRepo.fetch(businessId: 'biz_1', invoiceId: issued.id);
      expect(live?.status, InvoiceStatus.partiallyPaid);

      final draftOnly = await invoices.save(
        InMemoryInvoiceRepository.sample(
          id: invoices.nextId(),
          invoiceNumber: '',
          invoiceSequence: 0,
          status: InvoiceStatus.draft,
        ),
        business: business,
        asDraft: true,
      );
      await Future<void>.delayed(Duration.zero);
      await invoices.delete(draftOnly);
      await Future<void>.delayed(Duration.zero);
      expect(invoices.byId(draftOnly.id), isNull);
    });
  });

  group('List pagination', () {
    test('customer watch respects page size and loadMore grows the window', () async {
      final many = [
        for (var i = 1; i <= AppConstants.listPageSize + 5; i++)
          InMemoryCustomerRepository.sample(id: 'cus_$i', name: 'Customer $i'),
      ];
      final repo = InMemoryCustomerRepository(customers: many);
      final customers = CustomerProvider(repo);
      addTearDown(customers.dispose);

      customers.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);
      expect(customers.allCustomers.length, AppConstants.listPageSize);
      expect(customers.hasMore, isTrue);

      await customers.loadMore();
      await Future<void>.delayed(Duration.zero);
      expect(customers.allCustomers.length, AppConstants.listPageSize + 5);
      expect(customers.hasMore, isFalse);
    });

    test('product watch is scoped to the bound business id', () async {
      final repo = InMemoryProductRepository(
        products: [
          InMemoryProductRepository.sample(id: 'prd_a', businessId: 'biz_1', name: 'A'),
          InMemoryProductRepository.sample(id: 'prd_b', businessId: 'biz_2', name: 'B', kind: ProductKind.service),
        ],
      );
      final products = ProductProvider(productRepository: repo, storageService: StorageService());
      addTearDown(products.dispose);

      products.bind(businessId: 'biz_1');
      await Future<void>.delayed(Duration.zero);
      expect(products.allProducts.map((p) => p.id), ['prd_a']);
    });
  });
}
