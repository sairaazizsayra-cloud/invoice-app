import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_load_more.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/models/invoice_status.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final invoices = context.watch<InvoiceProvider>();
    final business = businessState.business;

    if ((businessState.isLoading && business == null) || (invoices.isLoading && invoices.allInvoices.isEmpty)) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.invoicesTitle)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final visible = invoices.visibleInvoices;
    final searching = invoices.query.trim().isNotEmpty || invoices.filter != InvoiceListFilter.all;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.invoicesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.invoiceNew),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addInvoice),
      ),
      body: AppPaddedBody(
        child: Column(
          children: [
            AppSearchField(
              controller: _searchController,
              hint: AppStrings.searchInvoicesHint,
              onChanged: invoices.setQuery,
              onClear: () => invoices.setQuery(''),
            ),
            const SizedBox(height: AppSpacing.md),
            _InvoiceFilterBar(selected: invoices.filter, onSelected: invoices.setFilter),
            const SizedBox(height: AppSpacing.md),
            if (invoices.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppErrorState(title: invoices.error!),
              ),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyState(
                      title: searching ? AppStrings.noInvoiceResultsTitle : AppStrings.emptyInvoicesTitle,
                      message: searching ? AppStrings.noInvoiceResultsBody : AppStrings.emptyInvoicesBody,
                      icon: Icons.receipt_long_outlined,
                      actionLabel: searching ? null : AppStrings.addInvoice,
                      onAction: searching ? null : () => context.push(AppRoutes.invoiceNew),
                    )
                  : ListView.separated(
                      itemCount: visible.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == visible.length) {
                          return AppLoadMoreBar(
                            visible: invoices.hasMore,
                            loading: invoices.isLoadingMore,
                            onPressed: () => invoices.loadMore(),
                          );
                        }
                        final invoice = visible[index];
                        return _InvoiceTile(
                          invoice: invoice,
                          now: now,
                          onTap: () => context.push(AppRoutes.invoiceDetail(invoice.id)),
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

class _InvoiceFilterBar extends StatelessWidget {
  const _InvoiceFilterBar({required this.selected, required this.onSelected});

  final InvoiceListFilter selected;
  final ValueChanged<InvoiceListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(InvoiceListFilter, String)>[
      (InvoiceListFilter.all, AppStrings.filterAll),
      (InvoiceListFilter.draft, AppStrings.filterDraft),
      (InvoiceListFilter.unpaid, AppStrings.filterUnpaid),
      (InvoiceListFilter.overdue, AppStrings.filterOverdue),
      (InvoiceListFilter.paid, AppStrings.filterPaid),
      (InvoiceListFilter.cancelled, AppStrings.filterCancelled),
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

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({
    required this.invoice,
    required this.now,
    required this.onTap,
  });

  final Invoice invoice;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        title: Text(invoice.invoiceNumber.isEmpty ? AppStrings.filterDraft : invoice.invoiceNumber),
        subtitle: Text(
          [
            invoice.customerName,
            AppDateFormatter.display(invoice.issueDate),
            invoice.displayStatus(now).label,
          ].join(' • '),
        ),
        trailing: Text(invoice.total.formatted),
      ),
    );
  }
}
