import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/product.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/product_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/invoices/invoice_pickers.dart';
import 'package:provider/provider.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key, this.invoiceId, this.customerId});

  final String? invoiceId;
  final String? customerId;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _issueDateText = TextEditingController();
  final TextEditingController _dueDateText = TextEditingController();
  String? _assignedId;
  String? _hydratedId;
  Customer? _customer;
  InvoicePaymentTerms _terms = InvoicePaymentTerms.dueOnReceipt;
  DateTime _issueDate = AppDateFormatter.startOfDay(DateTime.now());
  DateTime _dueDate = AppDateFormatter.startOfDay(DateTime.now());
  List<InvoiceLine> _lines = const [];
  String _invoiceNumber = '';
  bool _seededCustomer = false;

  bool get _isEditing => widget.invoiceId != null;

  @override
  void initState() {
    super.initState();
    _syncDateTexts();
  }

  @override
  void dispose() {
    _notes.dispose();
    _issueDateText.dispose();
    _dueDateText.dispose();
    super.dispose();
  }

  void _syncDateTexts() {
    _issueDateText.text = AppDateFormatter.display(_issueDate);
    _dueDateText.text = AppDateFormatter.display(_dueDate);
  }

  void _hydrate(Invoice invoice) {
    if (_hydratedId == invoice.id) return;
    _hydratedId = invoice.id;
    _assignedId = invoice.id;
    _invoiceNumber = invoice.invoiceNumber;
    _customer = _customerFromInvoice(invoice);
    _terms = invoice.paymentTerms;
    _issueDate = AppDateFormatter.startOfDay(invoice.issueDate);
    _dueDate = AppDateFormatter.startOfDay(invoice.dueDate);
    _lines = invoice.items;
    _notes.text = invoice.notes;
    _syncDateTexts();
  }

  Customer _customerFromInvoice(Invoice invoice) {
    return Customer(
      id: invoice.customerId,
      businessId: invoice.businessId,
      name: invoice.customerName,
      company: invoice.customerCompany,
      email: invoice.customerEmail,
      phone: invoice.customerPhone,
      address: invoice.customerAddress,
      city: invoice.customerCity,
    );
  }

  void _seedCustomer(CustomerProvider customers) {
    if (_seededCustomer || widget.customerId == null) return;
    final customer = customers.byId(widget.customerId!);
    if (customer == null) return;
    _seededCustomer = true;
    _customer = customer;
  }

  Invoice _buildDraft(Business business, Invoice? existing) {
    final id = existing?.id ?? (_assignedId ??= context.read<InvoiceProvider>().nextId());
    var invoice = (existing ?? Invoice.draft(id: id, business: business, now: _issueDate))
        .withBusinessSnapshot(business)
        .copyWith(
          paymentTerms: _terms,
          issueDate: _issueDate,
          dueDate: _dueDate,
          notes: _notes.text.trim(),
          invoiceNumber: existing?.invoiceNumber ?? _invoiceNumber,
          invoiceSequence: existing?.invoiceSequence ?? 0,
          status: existing?.status,
        )
        .withItems(_lines);
    final customer = _customer;
    if (customer != null) {
      invoice = invoice.withCustomer(customer);
    }
    return invoice;
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _issueDate = AppDateFormatter.startOfDay(picked);
      if (_terms != InvoicePaymentTerms.custom) {
        _dueDate = _terms.dueDateFrom(_issueDate);
      }
      _syncDateTexts();
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_issueDate) ? _issueDate : _dueDate,
      firstDate: _issueDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _terms = InvoicePaymentTerms.custom;
      _dueDate = AppDateFormatter.startOfDay(picked);
      _syncDateTexts();
    });
  }

  Future<void> _pickCustomer() async {
    final customers = context.read<CustomerProvider>();
    final selected = await showCustomerPickerSheet(
      context: context,
      customers: customers.allCustomers,
      onAddCustomer: () => unawaited(_addCustomer()),
    );
    if (selected == null || !mounted) return;
    setState(() => _customer = selected);
  }

  Future<void> _addCustomer() async {
    final created = await context.push<Customer>(AppRoutes.customerNew);
    if (created == null || !mounted) return;
    setState(() => _customer = created);
  }

  Future<void> _addLine() async {
    final products = context.read<ProductProvider>();
    final pick = await showProductPickerSheet(context: context, products: products.allProducts);
    if (!mounted) return;
    if (pick == null) return;
    if (pick.isCustom) {
      final custom = await showInvoiceLineSheet(
        context: context,
        currencyCode: products.currencyCode,
      );
      if (custom == null || !mounted) return;
      setState(() => _lines = [..._lines, custom]);
      return;
    }
    final product = pick.product;
    if (product == null) return;
    setState(() => _lines = [..._lines, _lineFromProduct(product, products.currencyCode)]);
  }

  InvoiceLine _lineFromProduct(Product product, String currencyCode) {
    return InvoiceLine.calculated(
      productId: product.id,
      name: product.name,
      description: product.description,
      unit: product.unit,
      quantity: 1,
      unitPriceMinor: product.priceMinor,
      taxPercentMinor: product.taxPercentMinor,
      currencyCode: currencyCode,
    );
  }

  Future<void> _editLine(int index) async {
    final currency = context.read<ProductProvider>().currencyCode;
    final updated = await showInvoiceLineSheet(
      context: context,
      currencyCode: currency,
      existing: _lines[index],
    );
    if (updated == null || !mounted) return;
    setState(() {
      final next = [..._lines];
      next[index] = updated;
      _lines = next;
    });
  }

  void _removeLine(int index) {
    setState(() {
      final next = [..._lines];
      next.removeAt(index);
      _lines = next;
    });
  }

  Future<void> _save({required bool asDraft}) async {
    final business = context.read<BusinessProvider>().business;
    final invoices = context.read<InvoiceProvider>();
    if (business == null) {
      AppSnackbar.error(context, AppStrings.businessMissing);
      return;
    }
    final existing = widget.invoiceId == null ? null : invoices.byId(widget.invoiceId!);
    final draft = _buildDraft(business, existing);
    try {
      await invoices.save(draft, business: business, asDraft: asDraft);
      if (!mounted) return;
      await context.read<CustomerProvider>().refreshOutstanding();
      if (!mounted) return;
      AppSnackbar.success(context, asDraft ? AppStrings.invoiceSaved : AppStrings.invoiceIssued);
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>().business;
    final invoices = context.watch<InvoiceProvider>();
    final customers = context.watch<CustomerProvider>();
    final existing = widget.invoiceId == null ? null : invoices.byId(widget.invoiceId!);
    _seedCustomer(customers);
    if (existing != null) {
      _hydrate(existing);
    }

    if (_isEditing && existing == null && !invoices.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editInvoice)),
        body: const AppErrorState(title: AppStrings.pageNotFound),
      );
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? AppStrings.editInvoice : AppStrings.addInvoice)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final busy = invoices.isSaving;
    final issued = existing != null && !existing.isDraft;
    final previewNumber = existing?.invoiceNumber.isNotEmpty == true
        ? existing!.invoiceNumber
        : Invoice.previewNumber(business);
    final totals = Invoice.draft(id: 'preview', business: business).withItems(_lines);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? AppStrings.editInvoice : AppStrings.addInvoice)),
      body: AppPaddedBody(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _BusinessHeader(business: business),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: busy ? null : () => unawaited(_pickCustomer()),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.selectCustomer, style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          _customer?.name ?? AppStrings.selectCustomer,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_customer?.subtitle.isNotEmpty == true)
                          Text(_customer!.subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: AppStrings.invoiceNumberLabel,
                  border: InputBorder.none,
                ),
                child: Text(previewNumber, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _issueDateText,
              label: AppStrings.invoiceDateLabel,
              readOnly: true,
              enabled: !busy,
              onTap: busy ? null : () => unawaited(_pickIssueDate()),
              prefixIcon: Icons.event_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<InvoicePaymentTerms>(
              key: ValueKey(_terms),
              initialValue: _terms,
              decoration: const InputDecoration(labelText: AppStrings.paymentTermsLabel),
              items: [
                for (final term in InvoicePaymentTerms.values)
                  DropdownMenuItem(value: term, child: Text(term.label)),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _terms = value;
                        if (value != InvoicePaymentTerms.custom) {
                          _dueDate = value.dueDateFrom(_issueDate);
                        }
                        _syncDateTexts();
                      });
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _dueDateText,
              label: AppStrings.dueDateLabel,
              readOnly: true,
              enabled: !busy,
              onTap: busy ? null : () => unawaited(_pickDueDate()),
              prefixIcon: Icons.event_available_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: AppStrings.invoiceItems,
              actionLabel: AppStrings.addInvoiceItem,
              onAction: busy ? null : () => unawaited(_addLine()),
            ),
            if (_lines.isEmpty)
              const AppCard(
                child: AppEmptyState(
                  title: AppStrings.emptyInvoiceItemsTitle,
                  message: AppStrings.emptyInvoiceItemsBody,
                  icon: Icons.playlist_add_outlined,
                ),
              )
            else
              ...[
                for (var i = 0; i < _lines.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _LineTile(
                      line: _lines[i],
                      currencyCode: business.currencyCode,
                      onTap: busy ? null : () => unawaited(_editLine(i)),
                      onDelete: busy ? null : () => _removeLine(i),
                    ),
                  ),
              ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _notes,
              label: AppStrings.invoiceNotesLabel,
              enabled: !busy,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TotalsCard(invoice: totals),
            const SizedBox(height: AppSpacing.xl),
            if (!issued)
              AppButton(
                label: AppStrings.saveDraft,
                expanded: true,
                variant: AppButtonVariant.tonal,
                isLoading: busy,
                onPressed: busy ? null : () => unawaited(_save(asDraft: true)),
              ),
            if (!issued) const SizedBox(height: AppSpacing.md),
            AppButton(
              label: issued ? AppStrings.save : AppStrings.issueInvoice,
              expanded: true,
              isLoading: busy,
              onPressed: busy ? null : () => unawaited(_save(asDraft: false)),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          ),
        ),
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            backgroundImage: business.logoUrl == null ? null : NetworkImage(business.logoUrl!),
            child: business.logoUrl == null ? const Icon(Icons.storefront_outlined) : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business.name, style: Theme.of(context).textTheme.titleLarge),
                if (business.address.isNotEmpty || business.city.isNotEmpty)
                  Text([business.address, business.city].where((part) => part.isNotEmpty).join(', ')),
                if (business.phone.isNotEmpty || business.email.isNotEmpty)
                  Text([business.phone, business.email].where((part) => part.isNotEmpty).join(' • ')),
                if (business.taxNumber.isNotEmpty) Text(business.taxNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.currencyCode,
    this.onTap,
    this.onDelete,
  });

  final InvoiceLine line;
  final String currencyCode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: onDelete == null
            ? null
            : IconButton(
                tooltip: AppStrings.delete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
        title: Text(line.name),
        subtitle: Text(
          [
            '${line.quantity} ${line.unit}',
            line.unitPrice(currencyCode: currencyCode).formatted,
            if (line.discountMinor > 0) line.discount(currencyCode: currencyCode).formatted,
          ].join(' • '),
        ),
        trailing: Text(line.lineTotal(currencyCode: currencyCode).formatted),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _totalRow(context, AppStrings.subtotalLabel, invoice.subtotal),
          _totalRow(context, AppStrings.discountLabel, invoice.discount),
          _totalRow(context, AppStrings.taxLabel, invoice.tax),
          const Divider(),
          _totalRow(context, AppStrings.grandTotalLabel, invoice.total, emphasize: true),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, Money amount, {bool emphasize = false}) {
    final style = emphasize ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(amount.formatted, style: style),
        ],
      ),
    );
  }
}
