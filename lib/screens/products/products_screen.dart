import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_load_more.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/product_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final products = context.watch<ProductProvider>();
    final business = businessState.business;

    if ((businessState.isLoading && business == null) || (products.isLoading && products.allProducts.isEmpty)) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.productsTitle)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final visible = products.visibleProducts;
    final searching = products.query.trim().isNotEmpty ||
        products.filter != ProductListFilter.all ||
        (products.categoryId != null && products.categoryId!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.productsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.productNew),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addProduct),
      ),
      body: AppPaddedBody(
        child: Column(
          children: [
            AppSearchField(
              controller: _searchController,
              hint: AppStrings.searchProductsHint,
              onChanged: products.setQuery,
              onClear: () => products.setQuery(''),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProductFilterBar(selected: products.filter, onSelected: products.setFilter),
            if (products.categories.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _CategoryFilterBar(
                categories: products.categories,
                selectedId: products.categoryId,
                onSelected: products.setCategoryId,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (products.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppErrorState(title: products.error!),
              ),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyState(
                      title: searching ? AppStrings.noProductResultsTitle : AppStrings.emptyProductsTitle,
                      message: searching ? AppStrings.noProductResultsBody : AppStrings.emptyProductsBody,
                      icon: Icons.inventory_2_outlined,
                      actionLabel: searching ? null : AppStrings.addProduct,
                      onAction: searching ? null : () => context.push(AppRoutes.productNew),
                    )
                  : ListView.separated(
                      itemCount: visible.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == visible.length) {
                          return AppLoadMoreBar(
                            visible: products.hasMore,
                            loading: products.isLoadingMore,
                            onPressed: () => products.loadMore(),
                          );
                        }
                        final product = visible[index];
                        return _ProductTile(
                          product: product,
                          priceLabel: product.price(currencyCode: products.currencyCode).formatted,
                          onTap: () => context.push(AppRoutes.productDetail(product.id)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFilterBar extends StatelessWidget {
  const _ProductFilterBar({required this.selected, required this.onSelected});

  final ProductListFilter selected;
  final ValueChanged<ProductListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(ProductListFilter, String)>[
      (ProductListFilter.all, AppStrings.filterAll),
      (ProductListFilter.products, AppStrings.filterProducts),
      (ProductListFilter.services, AppStrings.filterServices),
      (ProductListFilter.lowStock, AppStrings.filterLowStock),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return ChoiceChip(
            label: Text(item.$2),
            selected: item.$1 == selected,
            onSelected: (_) => onSelected(item.$1),
          );
        },
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProductCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text(AppStrings.filterAllCategories),
              selected: selectedId == null || selectedId!.isEmpty,
              onSelected: (_) => onSelected(null),
            );
          }
          final category = categories[index - 1];
          return ChoiceChip(
            label: Text(category.name),
            selected: selectedId == category.id,
            onSelected: (_) => onSelected(category.id),
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.priceLabel,
    required this.onTap,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          backgroundImage: product.imageUrl == null ? null : NetworkImage(product.imageUrl!),
          child: product.imageUrl == null ? Text(product.initials) : null,
        ),
        title: Text(product.name),
        subtitle: Text(
          [
            product.kind.label,
            if (product.categoryName.isNotEmpty) product.categoryName,
            if (product.isLowStock) AppStrings.lowStockLabel else if (product.trackStock && product.isProduct)
              '${product.stockQuantity} ${product.unit}',
          ].join(' • '),
        ),
        trailing: Text(priceLabel),
      ),
    );
  }
}
