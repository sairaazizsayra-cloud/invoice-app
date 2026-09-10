import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_load_more.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final customers = context.watch<CustomerProvider>();
    final business = businessState.business;

    if ((businessState.isLoading && business == null) || (customers.isLoading && customers.allCustomers.isEmpty)) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.customersTitle)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final visible = customers.visibleCustomers;
    final searching = customers.query.trim().isNotEmpty || customers.filter != CustomerListFilter.all;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.customersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.customerNew),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(AppStrings.addCustomer),
      ),
      body: AppPaddedBody(
        child: Column(
          children: [
            AppSearchField(
              controller: _searchController,
              hint: AppStrings.searchCustomersHint,
              onChanged: customers.setQuery,
              onClear: () => customers.setQuery(''),
            ),
            const SizedBox(height: AppSpacing.md),
            _CustomerFilterBar(
              selected: customers.filter,
              onSelected: customers.setFilter,
            ),
            const SizedBox(height: AppSpacing.md),
            if (customers.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppErrorState(title: customers.error!),
              ),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyState(
                      title: searching ? AppStrings.noCustomerResultsTitle : AppStrings.emptyCustomersTitle,
                      message: searching
                          ? AppStrings.noCustomerResultsBody
                          : AppStrings.emptyCustomersBody,
                      icon: Icons.groups_outlined,
                      actionLabel: searching ? null : AppStrings.addCustomer,
                      onAction: searching ? null : () => context.push(AppRoutes.customerNew),
                    )
                  : ListView.separated(
                      itemCount: visible.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == visible.length) {
                          return AppLoadMoreBar(
                            visible: customers.hasMore,
                            loading: customers.isLoadingMore,
                            onPressed: () => customers.loadMore(),
                          );
                        }
                        final customer = visible[index];
                        return _CustomerTile(
                          customer: customer,
                          outstanding: customers.outstandingOf(customer.id),
                          onTap: () => context.push(AppRoutes.customerDetail(customer.id)),
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

class _CustomerFilterBar extends StatelessWidget {
  const _CustomerFilterBar({required this.selected, required this.onSelected});

  final CustomerListFilter selected;
  final ValueChanged<CustomerListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(CustomerListFilter, String)>[
      (CustomerListFilter.all, AppStrings.filterAll),
      (CustomerListFilter.outstanding, AppStrings.filterOutstanding),
      (CustomerListFilter.hasEmail, AppStrings.filterHasEmail),
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

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.outstanding,
    required this.onTap,
  });

  final Customer customer;
  final Money outstanding;
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
          child: Text(customer.initials),
        ),
        title: Text(customer.name),
        subtitle: Text(
          customer.subtitle.isEmpty ? AppStrings.customerDetails : customer.subtitle,
        ),
        trailing: outstanding.isPositive ? Text(outstanding.formatted) : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
