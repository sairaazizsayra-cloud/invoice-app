import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:provider/provider.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key, required this.invoiceId, this.settleInFull = false});

  final String invoiceId;
  final bool settleInFull;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _dateText = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paidAt = AppDateFormatter.startOfDay(DateTime.now());
  bool _hydrated = false;

  @override
  void dispose() {
    _amount.dispose();
    _dateText.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(Money outstanding) {
    if (_hydrated) return;
    _hydrated = true;
    _dateText.text = AppDateFormatter.display(_paidAt);
    if (widget.settleInFull || outstanding.isPositive) {
      _amount.text = outstanding.format(includeSymbol: false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _paidAt = AppDateFormatter.startOfDay(picked);
      _dateText.text = AppDateFormatter.display(_paidAt);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final invoice = context.read<InvoiceProvider>().byId(widget.invoiceId);
    if (invoice == null) {
      AppSnackbar.error(context, AppStrings.invoiceMissing);
      return;
    }
    try {
      final amount = Money.parse(_amount.text, currencyCode: invoice.currencyCode);
      await context.read<PaymentProvider>().record(
        invoice: invoice,
        amountMinor: amount.minorUnits,
        method: _method,
        paidAt: _paidAt,
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      await context.read<CustomerProvider>().refreshOutstanding();
      if (!mounted) return;
      AppSnackbar.success(
        context,
        widget.settleInFull ? AppStrings.invoiceMarkedPaid : AppStrings.paymentRecorded,
      );
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>();
    final payments = context.watch<PaymentProvider>();
    final invoice = invoices.byId(widget.invoiceId);

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.settleInFull ? AppStrings.markPaid : AppStrings.recordPayment)),
        body: invoices.isLoading
            ? const AppLoading(message: AppStrings.loading)
            : const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    _hydrate(invoice.outstanding);
    final busy = payments.isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(widget.settleInFull ? AppStrings.markPaid : AppStrings.recordPayment)),
      body: AppPaddedBody(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.invoiceNumber, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text('${AppStrings.grandTotalLabel}: ${invoice.total.formatted}'),
                      Text('${AppStrings.amountPaidLabel}: ${invoice.paid.formatted}'),
                      Text('${AppStrings.remainingBalanceLabel}: ${invoice.outstanding.formatted}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _amount,
                  label: AppStrings.paymentAmountLabel,
                  enabled: !busy && !widget.settleInFull,
                  readOnly: widget.settleInFull,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => AppValidators.paymentAmount(value, maximum: invoice.outstanding),
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<PaymentMethod>(
                  key: ValueKey(_method),
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: AppStrings.paymentMethodLabel),
                  items: [
                    for (final method in PaymentMethod.values)
                      DropdownMenuItem(value: method, child: Text(method.label)),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _method = value);
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _dateText,
                  label: AppStrings.paymentDateLabel,
                  readOnly: true,
                  enabled: !busy,
                  onTap: busy ? null : () => unawaited(_pickDate()),
                  prefixIcon: Icons.event_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _notes,
                  label: AppStrings.paymentNotesLabel,
                  enabled: !busy,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: widget.settleInFull ? AppStrings.markPaid : AppStrings.recordPayment,
                  expanded: true,
                  isLoading: busy,
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
