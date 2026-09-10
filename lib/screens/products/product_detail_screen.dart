import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_stat_card.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/providers/product_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  Future<void> _delete(BuildContext context, Product product) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteProductTitle,
      message: AppStrings.deleteProductBody,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<ProductProvider>().delete(product);
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.productDeleted);
      context.pop();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final product = products.byId(productId);
    final scheme = Theme.of(context).colorScheme;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.productDetails)),
        body: products.isLoading
            ? const AppLoading(message: AppStrings.loading)
            : const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    final stockLabel = !product.trackStock || product.isService
        ? AppStrings.notTrackedLabel
        : product.isLowStock
        ? AppStrings.lowStockLabel
        : AppStrings.inStockLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.productDetails),
        actions: [
          IconButton(
            tooltip: AppStrings.editProduct,
            onPressed: () => context.push(AppRoutes.productEdit(product.id)),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: AppStrings.delete,
            onPressed: products.isSaving ? null : () => unawaited(_delete(context, product)),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: AppPaddedBody(
        child: ListView(
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    backgroundImage: product.imageUrl == null ? null : NetworkImage(product.imageUrl!),
                    child: product.imageUrl == null ? Text(product.initials) : null,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(product.kind.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: AppStatCard(
                      label: AppStrings.priceLabel,
                      value: product.price(currencyCode: products.currencyCode).formatted,
                      icon: Icons.sell_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: AppStatCard(
                      label: stockLabel,
                      value: product.trackStock && product.isProduct
                          ? '${product.stockQuantity} ${product.unit}'
                          : '—',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (product.sku.isNotEmpty)
                    ListTile(leading: const Icon(Icons.qr_code_outlined), title: Text(product.sku), subtitle: const Text(AppStrings.skuLabel)),
                  if (product.categoryName.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(product.categoryName),
                      subtitle: const Text(AppStrings.categoryLabel),
                    ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(product.cost(currencyCode: products.currencyCode).formatted),
                    subtitle: const Text(AppStrings.costPriceLabel),
                  ),
                  ListTile(
                    leading: const Icon(Icons.percent_outlined),
                    title: Text('${Money.fromMinorUnits(product.taxPercentMinor).format(includeSymbol: false)}%'),
                    subtitle: const Text(AppStrings.defaultTaxLabel),
                  ),
                  if (product.description.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.notes_outlined),
                      title: Text(product.description),
                      subtitle: const Text(AppStrings.descriptionLabel),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
