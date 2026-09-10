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
import 'package:invoice_pro/core/widgets/app_status_chip.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/invoices/invoice_pdf_actions.dart';
import 'package:provider/provider.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  Future<void> _delete(BuildContext context, Invoice invoice) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteInvoiceTitle,
      message: AppStrings.deleteInvoiceBody,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<InvoiceProvider>().delete(invoice);
      if (!context.mounted) return;
      await context.read<CustomerProvider>().refreshOutstanding();
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.invoiceDeleted);
      context.pop();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _cancel(BuildContext context, Invoice invoice) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.cancelInvoiceTitle,
      message: AppStrings.cancelInvoiceBody,
      confirmLabel: AppStrings.confirm,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<InvoiceProvider>().cancel(invoice);
      if (!context.mounted) return;
      await context.read<CustomerProvider>().refreshOutstanding();
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.invoiceCancelled);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _markSent(BuildContext context, Invoice invoice) async {
    try {
      await context.read<InvoiceProvider>().markSent(invoice);
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.invoiceMarkedSent);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _duplicate(BuildContext context, Invoice invoice) async {
    final business = context.read<BusinessProvider>().business;
    if (business == null) {
      AppSnackbar.error(context, AppStrings.businessMissing);
      return;
    }
    try {
      final copy = await context.read<InvoiceProvider>().duplicate(
        invoice,
        business: business,
        now: DateTime.now(),
      );
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.invoiceDuplicated);
      unawaited(context.push(AppRoutes.invoiceEdit(copy.id)));
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _deletePayment(BuildContext context, Payment payment) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentBody,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<PaymentProvider>().delete(payment);
      if (!context.mounted) return;
      await context.read<CustomerProvider>().refreshOutstanding();
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.paymentDeleted);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>();
    final payments = context.watch<PaymentProvider>();
    final invoice = invoices.byId(invoiceId);
    final now = DateTime.now();

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.invoiceDetails)),
        body: invoices.isLoading
            ? const AppLoading(message: AppStrings.loading)
            : const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.invoiceDetails),
        actions: [
          if (invoice.canEdit)
            IconButton(
              tooltip: AppStrings.editInvoice,
              onPressed: () => context.push(AppRoutes.invoiceEdit(invoice.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: AppStrings.duplicateInvoice,
            onPressed: invoices.isSaving ? null : () => unawaited(_duplicate(context, invoice)),
            icon: const Icon(Icons.copy_outlined),
          ),
          if (invoice.canDelete)
            IconButton(
              tooltip: AppStrings.delete,
              onPressed: invoices.isSaving ? null : () => unawaited(_delete(context, invoice)),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: AppPaddedBody(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(invoice.invoiceNumber, style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      AppStatusChip(status: invoice.displayStatus(now)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(invoice.businessName, style: Theme.of(context).textTheme.titleMedium),
                  if (invoice.businessAddress.isNotEmpty || invoice.businessCity.isNotEmpty)
                    Text(
                      [invoice.businessAddress, invoice.businessCity].where((part) => part.isNotEmpty).join(', '),
                    ),
                  if (invoice.businessPhone.isNotEmpty || invoice.businessEmail.isNotEmpty)
                    Text(
                      [invoice.businessPhone, invoice.businessEmail].where((part) => part.isNotEmpty).join(' • '),
                    ),
                  if (invoice.businessTaxNumber.isNotEmpty) Text(invoice.businessTaxNumber),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.selectCustomer, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(invoice.customerName, style: Theme.of(context).textTheme.titleMedium),
                  if (invoice.customerCompany.isNotEmpty) Text(invoice.customerCompany),
                  if (invoice.customerPhone.isNotEmpty) Text(invoice.customerPhone),
                  if (invoice.customerEmail.isNotEmpty) Text(invoice.customerEmail),
                  if (invoice.customerAddress.isNotEmpty || invoice.customerCity.isNotEmpty)
                    Text(
                      [invoice.customerAddress, invoice.customerCity].where((part) => part.isNotEmpty).join(', '),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text(AppStrings.invoiceDateLabel),
                    trailing: Text(AppDateFormatter.display(invoice.issueDate)),
                  ),
                  ListTile(
                    title: const Text(AppStrings.dueDateLabel),
                    trailing: Text(AppDateFormatter.display(invoice.dueDate)),
                  ),
                  ListTile(
                    title: const Text(AppStrings.paymentTermsLabel),
                    trailing: Text(invoice.paymentTerms.label),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: AppStrings.invoiceItems),
            if (invoice.items.isEmpty)
              const AppCard(
                child: AppEmptyState(
                  title: AppStrings.emptyInvoiceItemsTitle,
                  message: AppStrings.emptyInvoiceItemsBody,
                  icon: Icons.playlist_add_outlined,
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final line in invoice.items)
                      ListTile(
                        title: Text(line.name),
                        subtitle: Text(
                          [
                            '${line.quantity} ${line.unit}',
                            line.unitPrice(currencyCode: invoice.currencyCode).formatted,
                          ].join(' • '),
                        ),
                        trailing: Text(line.lineTotal(currencyCode: invoice.currencyCode).formatted),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                children: [
                  _amountRow(context, AppStrings.subtotalLabel, invoice.subtotal),
                  _amountRow(context, AppStrings.discountLabel, invoice.discount),
                  _amountRow(context, AppStrings.taxLabel, invoice.tax),
                  const Divider(),
                  _amountRow(context, AppStrings.grandTotalLabel, invoice.total, emphasize: true),
                  _amountRow(context, AppStrings.amountPaidLabel, invoice.paid),
                  _amountRow(context, AppStrings.amountDueLabel, invoice.outstanding, emphasize: true),
                ],
              ),
            ),
            if (invoice.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.invoiceNotesLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(invoice.notes),
                  ],
                ),
              ),
            ],
            if (invoice.paymentInstructions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.paymentInstructionsLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(invoice.paymentInstructions),
                  ],
                ),
              ),
            ],
            if (invoice.termsAndConditions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.termsLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(invoice.termsAndConditions),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: AppStrings.paymentHistory),
            _InvoicePaymentHistory(
              payments: payments.forInvoice(invoice.id),
              onDelete: payments.isSaving ? null : (payment) => unawaited(_deletePayment(context, payment)),
            ),
            if (invoice.canRecordPayment) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: AppStrings.recordPayment,
                expanded: true,
                isLoading: payments.isSaving,
                onPressed: payments.isSaving
                    ? null
                    : () => context.push(AppRoutes.invoicePay(invoice.id)),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: AppStrings.markPaid,
                expanded: true,
                variant: AppButtonVariant.tonal,
                isLoading: payments.isSaving,
                onPressed: payments.isSaving
                    ? null
                    : () => context.push(AppRoutes.invoicePay(invoice.id, settleInFull: true)),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            InvoicePdfActions(invoice: invoice),
            const SizedBox(height: AppSpacing.xl),
            if (invoice.canMarkSent)
              AppButton(
                label: AppStrings.markSent,
                expanded: true,
                variant: AppButtonVariant.tonal,
                isLoading: invoices.isSaving,
                onPressed: invoices.isSaving ? null : () => unawaited(_markSent(context, invoice)),
              ),
            if (invoice.canMarkSent) const SizedBox(height: AppSpacing.md),
            if (invoice.canCancel)
              AppButton(
                label: AppStrings.cancelInvoiceAction,
                expanded: true,
                variant: AppButtonVariant.outlined,
                isLoading: invoices.isSaving,
                onPressed: invoices.isSaving ? null : () => unawaited(_cancel(context, invoice)),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          ),
        ),
      ),
    );
  }

  Widget _amountRow(BuildContext context, String label, Money amount, {bool emphasize = false}) {
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

class _InvoicePaymentHistory extends StatelessWidget {
  const _InvoicePaymentHistory({required this.payments, this.onDelete});

  final List<Payment> payments;
  final ValueChanged<Payment>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyInvoicePaymentsTitle,
          message: AppStrings.emptyInvoicePaymentsBody,
          icon: Icons.payments_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final payment in payments)
            ListTile(
              title: Text(payment.amount.formatted),
              subtitle: Text(
                [
                  payment.method.label,
                  AppDateFormatter.display(payment.paidAt),
                  if (payment.notes.isNotEmpty) payment.notes,
                ].join(' • '),
              ),
              trailing: onDelete == null
                  ? null
                  : IconButton(
                      tooltip: AppStrings.delete,
                      onPressed: () => onDelete!(payment),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
            ),
        ],
      ),
    );
  }
}
