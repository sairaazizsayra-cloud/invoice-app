import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/line_amount_calculator.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/product.dart';

Future<Customer?> showCustomerPickerSheet({
  required BuildContext context,
  required List<Customer> customers,
  required VoidCallback onAddCustomer,
}) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CustomerPickerSheet(customers: customers, onAddCustomer: onAddCustomer),
  );
}

Future<InvoiceItemPick?> showProductPickerSheet({
  required BuildContext context,
  required List<Product> products,
}) {
  return showModalBottomSheet<InvoiceItemPick>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProductPickerSheet(products: products),
  );
}

class InvoiceItemPick {
  const InvoiceItemPick.product(this.product) : isCustom = false;
  const InvoiceItemPick.custom() : product = null, isCustom = true;

  final Product? product;
  final bool isCustom;
}

Future<InvoiceLine?> showInvoiceLineSheet({
  required BuildContext context,
  required String currencyCode,
  InvoiceLine? existing,
}) {
  return showModalBottomSheet<InvoiceLine>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _InvoiceLineSheet(currencyCode: currencyCode, existing: existing),
  );
}

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.customers, required this.onAddCustomer});

  final List<Customer> customers;
  final VoidCallback onAddCustomer;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.customers.where((customer) => customer.matches(_query.text)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            children: [
              Text(AppStrings.selectCustomer, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppSearchField(
                controller: _query,
                hint: AppStrings.searchCustomersHint,
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onAddCustomer();
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text(AppStrings.addInvoiceCustomer),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const AppEmptyState(
                        title: AppStrings.noCustomersForInvoiceTitle,
                        message: AppStrings.noCustomersForInvoiceBody,
                        icon: Icons.groups_outlined,
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final customer = visible[index];
                          return ListTile(
                            title: Text(customer.name),
                            subtitle: Text(
                              customer.subtitle.isEmpty ? AppStrings.customerDetails : customer.subtitle,
                            ),
                            onTap: () => Navigator.pop(context, customer),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products});

  final List<Product> products;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.products.where((product) => product.matches(_query.text)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            children: [
              Text(AppStrings.selectProduct, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppSearchField(
                controller: _query,
                hint: AppStrings.searchProductsHint,
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context, const InvoiceItemPick.custom()),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(AppStrings.customItem),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const AppEmptyState(
                        title: AppStrings.noProductsForInvoiceTitle,
                        message: AppStrings.noProductsForInvoiceBody,
                        icon: Icons.inventory_2_outlined,
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final product = visible[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(product.kind.label),
                            trailing: Text(product.price().formatted),
                            onTap: () => Navigator.pop(context, InvoiceItemPick.product(product)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceLineSheet extends StatefulWidget {
  const _InvoiceLineSheet({required this.currencyCode, this.existing});

  final String currencyCode;
  final InvoiceLine? existing;

  @override
  State<_InvoiceLineSheet> createState() => _InvoiceLineSheetState();
}

class _InvoiceLineSheetState extends State<_InvoiceLineSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late String _unit;
  late String _productId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _productId = existing?.productId ?? '';
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _quantity = TextEditingController(text: existing == null ? '1' : '${existing.quantity}');
    _unitPrice = TextEditingController(
      text: existing == null ? '' : existing.unitPrice(currencyCode: widget.currencyCode).format(includeSymbol: false),
    );
    _discount = TextEditingController(
      text: existing == null ? '0.00' : existing.discount(currencyCode: widget.currencyCode).format(includeSymbol: false),
    );
    _tax = TextEditingController(
      text: existing == null
          ? Money.fromMinorUnits(0).format(includeSymbol: false)
          : Money.fromMinorUnits(existing.taxPercentMinor).format(includeSymbol: false),
    );
    _unit = existing?.unit ?? AppConstants.defaultProductUnit;
    if (!AppConstants.productUnits.contains(_unit)) {
      _unit = AppConstants.defaultProductUnit;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _discount.dispose();
    _tax.dispose();
    super.dispose();
  }

  InvoiceLine? _buildLine() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    final quantity = int.parse(_quantity.text.trim());
    final unitPrice = Money.parse(_unitPrice.text, currencyCode: widget.currencyCode);
    final discount = Money.parse(_discount.text.isEmpty ? '0' : _discount.text, currencyCode: widget.currencyCode);
    final taxPercentMinor = Money.parse(_tax.text.isEmpty ? '0' : _tax.text).minorUnits;
    final subtotal = unitPrice.timesQuantity(quantity);
    if (discount.minorUnits > subtotal.minorUnits) {
      AppSnackbar.error(context, AppStrings.discountExceedsSubtotal);
      return null;
    }
    try {
      return InvoiceLine.calculated(
        productId: _productId,
        name: _name.text.trim(),
        description: _description.text.trim(),
        unit: _unit,
        quantity: quantity,
        unitPriceMinor: unitPrice.minorUnits,
        discountMinor: discount.minorUnits,
        taxPercentMinor: taxPercentMinor,
        currencyCode: widget.currencyCode,
      );
    } on ArgumentError {
      AppSnackbar.error(context, AppStrings.discountExceedsSubtotal);
      return null;
    }
  }

  String _previewTotal() {
    try {
      final quantity = int.parse(_quantity.text.trim());
      final unitPrice = Money.parse(_unitPrice.text, currencyCode: widget.currencyCode);
      final discount = Money.parse(_discount.text.isEmpty ? '0' : _discount.text, currencyCode: widget.currencyCode);
      final taxPercentMinor = Money.parse(_tax.text.isEmpty ? '0' : _tax.text).minorUnits;
      final result = LineAmountCalculator.calculate(
        unitPrice: unitPrice,
        quantity: quantity,
        discountAmount: discount,
        taxPercentMinor: taxPercentMinor,
      );
      return result.total.formatted;
    } catch (_) {
      return Money.zero(currencyCode: widget.currencyCode).formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? AppStrings.addInvoiceItem : AppStrings.editInvoiceItem,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _name,
                label: AppStrings.productNameLabel,
                validator: AppValidators.name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _description,
                label: AppStrings.descriptionLabel,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _quantity,
                label: AppStrings.quantityLabel,
                validator: AppValidators.positiveInt,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: AppStrings.unitLabel),
                items: [
                  for (final unit in AppConstants.productUnits) DropdownMenuItem(value: unit, child: Text(unit)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _unit = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _unitPrice,
                label: AppStrings.unitPriceLabel,
                validator: (value) => AppValidators.amount(value, allowZero: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _discount,
                label: AppStrings.discountLabel,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return AppValidators.amount(value, allowZero: true);
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _tax,
                label: AppStrings.taxLabel,
                validator: AppValidators.taxPercent,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('${AppStrings.lineTotalLabel}: ${_previewTotal()}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: AppStrings.save,
                expanded: true,
                onPressed: () {
                  final line = _buildLine();
                  if (line != null) Navigator.pop(context, line);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
