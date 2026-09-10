import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/product_provider.dart';
import 'package:provider/provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const String _noCategory = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _sku = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _tax = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _reorder = TextEditingController();

  ProductKind _kind = ProductKind.product;
  String _categoryId = _noCategory;
  String _unit = AppConstants.defaultProductUnit;
  String? _imageUrl;
  String? _assignedId;
  String? _hydratedId;
  bool _uploadingImage = false;

  bool get _isEditing => widget.productId != null;
  bool get _trackStock => _kind == ProductKind.product;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _description.dispose();
    _price.dispose();
    _cost.dispose();
    _tax.dispose();
    _stock.dispose();
    _reorder.dispose();
    super.dispose();
  }

  void _hydrate(Product product, {required int defaultTaxMinor}) {
    if (_hydratedId == product.id) return;
    _hydratedId = product.id;
    _assignedId = product.id;
    _name.text = product.name;
    _sku.text = product.sku;
    _description.text = product.description;
    _price.text = product.price().format(includeSymbol: false);
    _cost.text = product.cost().format(includeSymbol: false);
    _tax.text = Money.fromMinorUnits(product.taxPercentMinor).format(includeSymbol: false);
    _stock.text = '${product.stockQuantity}';
    _reorder.text = '${product.reorderLevel}';
    _kind = product.kind;
    _categoryId = product.categoryId;
    _unit = AppConstants.productUnits.contains(product.unit) ? product.unit : AppConstants.defaultProductUnit;
    _imageUrl = product.imageUrl;
  }

  void _seedNew(int defaultTaxMinor) {
    if (_hydratedId != null) return;
    _hydratedId = 'new';
    _tax.text = Money.fromMinorUnits(defaultTaxMinor).format(includeSymbol: false);
    _stock.text = '0';
    _reorder.text = '${AppConstants.defaultReorderLevel}';
    _cost.text = '0.00';
  }

  String _idForSave(ProductProvider products) {
    return _assignedId ??= products.nextProductId();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final business = context.read<BusinessProvider>().business;
    final products = context.read<ProductProvider>();
    if (business == null) {
      AppSnackbar.error(context, AppStrings.businessMissing);
      return;
    }

    final category = _categoryId.isEmpty ? null : products.categoryById(_categoryId);
    final draft = Product(
      id: _idForSave(products),
      businessId: business.id,
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      description: _description.text.trim(),
      kind: _kind,
      categoryId: category?.id ?? '',
      categoryName: category?.name ?? '',
      priceMinor: Money.parse(_price.text).minorUnits,
      costMinor: Money.parse(_cost.text.isEmpty ? '0' : _cost.text).minorUnits,
      taxPercentMinor: Money.parse(_tax.text).minorUnits,
      stockQuantity: _trackStock ? int.parse(_stock.text.trim()) : 0,
      reorderLevel: _trackStock ? int.parse(_reorder.text.trim()) : AppConstants.defaultReorderLevel,
      trackStock: _trackStock,
      unit: _unit,
      imageUrl: _imageUrl,
    );

    try {
      await products.save(draft);
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.productSaved);
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _pickImage() async {
    final products = context.read<ProductProvider>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.imagePickMaxDimension,
      maxHeight: AppConstants.imagePickMaxDimension,
      imageQuality: AppConstants.imagePickQuality,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await products.uploadImage(productId: _idForSave(products), bytes: bytes);
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, AppStrings.productImageFailed);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.addCategory),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: AppStrings.categoryNameLabel),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text(AppStrings.save),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final created = await context.read<ProductProvider>().addCategory(name);
      if (!mounted) return;
      setState(() => _categoryId = created.id);
      AppSnackbar.success(context, AppStrings.categorySaved);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final business = context.watch<BusinessProvider>().business;
    final existing = widget.productId == null ? null : products.byId(widget.productId!);
    final defaultTax = business?.defaultTaxPercentMinor ?? AppConstants.defaultTaxPercentMinor;

    if (_isEditing && existing != null) {
      _hydrate(existing, defaultTaxMinor: defaultTax);
    } else if (!_isEditing) {
      _seedNew(defaultTax);
    }

    if (_isEditing && existing == null && !products.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editProduct)),
        body: const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    final busy = products.isSaving || _uploadingImage;
    final categories = products.categories;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct)),
      body: AppPaddedBody(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: _imageUrl == null ? null : NetworkImage(_imageUrl!),
                        child: _imageUrl == null
                            ? Icon(
                                Icons.inventory_2_outlined,
                                size: 36,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      TextButton.icon(
                        onPressed: busy ? null : () => unawaited(_pickImage()),
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(_uploadingImage ? AppStrings.loading : AppStrings.pickProductImage),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<ProductKind>(
                  segments: const [
                    ButtonSegment(value: ProductKind.product, label: Text(AppStrings.kindProduct)),
                    ButtonSegment(value: ProductKind.service, label: Text(AppStrings.kindService)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: busy
                      ? null
                      : (value) => setState(() => _kind = value.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _name,
                  label: AppStrings.productNameLabel,
                  enabled: !busy,
                  validator: AppValidators.name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _sku,
                  label: AppStrings.skuLabel,
                  enabled: !busy,
                  validator: AppValidators.optionalSku,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _description,
                  label: AppStrings.descriptionLabel,
                  enabled: !busy,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  key: ValueKey('category-$_categoryId-${categories.length}'),
                  initialValue: categories.any((item) => item.id == _categoryId) ? _categoryId : _noCategory,
                  decoration: const InputDecoration(labelText: AppStrings.categoryLabel),
                  items: [
                    const DropdownMenuItem(value: _noCategory, child: Text('None')),
                    for (final category in categories)
                      DropdownMenuItem(value: category.id, child: Text(category.name)),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _categoryId = value);
                        },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: busy ? null : () => unawaited(_addCategory()),
                    child: const Text(AppStrings.addCategory),
                  ),
                ),
                AppTextField(
                  controller: _price,
                  label: AppStrings.priceLabel,
                  enabled: !busy,
                  validator: (value) => AppValidators.amount(value, allowZero: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _cost,
                  label: AppStrings.costPriceLabel,
                  enabled: !busy,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return AppValidators.amount(value, allowZero: true);
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _tax,
                  label: AppStrings.defaultTaxLabel,
                  enabled: !busy,
                  validator: AppValidators.taxPercent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: AppStrings.unitLabel),
                  items: [
                    for (final unit in AppConstants.productUnits) DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _unit = value);
                        },
                ),
                if (_trackStock) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _stock,
                    label: AppStrings.stockLabel,
                    enabled: !busy,
                    validator: (value) => AppValidators.nonNegativeInt(value, isRequired: true),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _reorder,
                    label: AppStrings.reorderLabel,
                    enabled: !busy,
                    validator: (value) => AppValidators.nonNegativeInt(value, isRequired: true),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: AppStrings.save,
                  expanded: true,
                  isLoading: products.isSaving,
                  onPressed: busy ? null : () => unawaited(_save()),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
