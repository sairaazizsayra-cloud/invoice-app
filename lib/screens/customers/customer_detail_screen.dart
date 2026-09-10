import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/customer_ledger.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_stat_card.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_status_chip.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/payment.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  CustomerLedger? _ledger;
  bool _loadingLedger = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadLedger());
    });
  }

  Future<void> _loadLedger() async {
    final customers = context.read<CustomerProvider>();
    final customer = customers.byId(widget.customerId);
    if (customer == null) {
      if (mounted) setState(() => _loadingLedger = false);
      return;
    }
    final ledger = await customers.ledgerFor(customer);
    if (!mounted) return;
    setState(() {
      _ledger = ledger;
      _loadingLedger = false;
    });
  }

  Future<void> _delete(Customer customer) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteCustomerTitle,
      message: AppStrings.deleteCustomerBody,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<CustomerProvider>().delete(customer);
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.customerDeleted);
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>();
    final business = context.watch<BusinessProvider>().business;
    final customer = customers.byId(widget.customerId);
    final semantic = Theme.of(context).colorScheme;

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.customerDetails)),
        body: customers.isLoading
            ? const AppLoading(message: AppStrings.loading)
            : const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    final ledger = _ledger ?? CustomerLedger.empty(currencyCode: business?.currencyCode ?? 'PKR');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.customerDetails),
        actions: [
          IconButton(
            tooltip: AppStrings.editCustomer,
            onPressed: () => context.push(AppRoutes.customerEdit(customer.id)),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: AppStrings.delete,
            onPressed: customers.isSaving ? null : () => unawaited(_delete(customer)),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: semantic.primaryContainer,
                    foregroundColor: semantic.onPrimaryContainer,
                    child: Text(customer.initials),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                        if (customer.company.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(customer.company),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ContactRows(customer: customer),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: AppStatCard(
                      label: AppStrings.totalPurchases,
                      value: ledger.totalPurchases.formatted,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: AppStatCard(
                      label: AppStrings.outstandingBalance,
                      value: ledger.outstanding.formatted,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: AppStrings.invoiceFromCustomer,
              expanded: true,
              icon: Icons.receipt_long_outlined,
              onPressed: () => context.push(AppRoutes.invoiceNewForCustomer(customer.id)),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: AppStrings.invoiceHistory),
            if (_loadingLedger)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppLoading(),
              )
            else
              _InvoiceHistory(invoices: ledger.invoices),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: AppStrings.paymentHistory),
            if (_loadingLedger)
              const SizedBox.shrink()
            else
              _PaymentHistory(payments: ledger.payments),
            const SizedBox(height: AppSpacing.xxl),
          ],
          ),
        ),
      ),
    );
  }
}

class _ContactRows extends StatelessWidget {
  const _ContactRows({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[
      if (customer.phone.isNotEmpty) (Icons.phone_outlined, customer.phone),
      if (customer.email.isNotEmpty) (Icons.mail_outline, customer.email),
      if (customer.address.isNotEmpty) (Icons.place_outlined, customer.address),
      if (customer.city.isNotEmpty) (Icons.location_city_outlined, customer.city),
      if (customer.notes.isNotEmpty) (Icons.notes_outlined, customer.notes),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              leading: Icon(row.$1),
              title: Text(row.$2),
            ),
        ],
      ),
    );
  }
}

class _InvoiceHistory extends StatelessWidget {
  const _InvoiceHistory({required this.invoices});

  final List<InvoiceRecord> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyCustomerInvoicesTitle,
          message: AppStrings.emptyCustomerInvoicesBody,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final invoice in invoices)
            ListTile(
              title: Text(invoice.number),
              subtitle: Text(
                [
                  invoice.total.formatted,
                  if (invoice.issueDate != null) AppDateFormatter.display(invoice.issueDate!),
                ].join(' • '),
              ),
              trailing: AppStatusChip(status: invoice.status),
              onTap: () => context.push(AppRoutes.invoiceDetail(invoice.id)),
            ),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyCustomerPaymentsTitle,
          message: AppStrings.emptyCustomerPaymentsBody,
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
                  if (payment.invoiceNumber.isNotEmpty) payment.invoiceNumber,
                  if (payment.method.isNotEmpty) PaymentMethodX.fromStorage(payment.method).label,
                  AppDateFormatter.display(payment.paidAt),
                ].join(' • '),
              ),
              onTap: payment.invoiceId.isEmpty
                  ? null
                  : () => context.push(AppRoutes.invoiceDetail(payment.invoiceId)),
            ),
        ],
      ),
    );
  }
}
