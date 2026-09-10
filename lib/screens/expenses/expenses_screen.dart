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
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/expense_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final business = businessState.business;

    if ((businessState.isLoading && business == null) || (expenses.isLoading && expenses.allExpenses.isEmpty)) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.expensesTitle)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final visible = expenses.visibleExpenses;
    final searching = expenses.query.trim().isNotEmpty || expenses.filter != ExpenseListFilter.all;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.expensesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.expenseNew),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addExpense),
      ),
      body: AppPaddedBody(
        child: Column(
          children: [
            AppSearchField(
              controller: _searchController,
              hint: AppStrings.searchExpensesHint,
              onChanged: expenses.setQuery,
              onClear: () => expenses.setQuery(''),
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpenseFilterBar(selected: expenses.filter, onSelected: expenses.setFilter),
            const SizedBox(height: AppSpacing.md),
            if (expenses.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppErrorState(title: expenses.error!),
              ),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyState(
                      title: searching ? AppStrings.noExpenseResultsTitle : AppStrings.emptyExpensesTitle,
                      message: searching ? AppStrings.noExpenseResultsBody : AppStrings.emptyExpensesBody,
                      icon: Icons.account_balance_wallet_outlined,
                      actionLabel: searching ? null : AppStrings.addExpense,
                      onAction: searching ? null : () => context.push(AppRoutes.expenseNew),
                    )
                  : ListView.separated(
                      itemCount: visible.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == visible.length) {
                          return AppLoadMoreBar(
                            visible: expenses.hasMore,
                            loading: expenses.isLoadingMore,
                            onPressed: () => expenses.loadMore(),
                          );
                        }
                        final expense = visible[index];
                        return _ExpenseTile(
                          expense: expense,
                          onTap: () => context.push(AppRoutes.expenseDetail(expense.id)),
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

class _ExpenseFilterBar extends StatelessWidget {
  const _ExpenseFilterBar({required this.selected, required this.onSelected});

  final ExpenseListFilter selected;
  final ValueChanged<ExpenseListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(ExpenseListFilter, String)>[
      (ExpenseListFilter.all, AppStrings.filterAll),
      (ExpenseListFilter.rent, ExpenseCategory.rent.label),
      (ExpenseListFilter.salary, ExpenseCategory.salary.label),
      (ExpenseListFilter.electricity, ExpenseCategory.electricity.label),
      (ExpenseListFilter.transport, ExpenseCategory.transport.label),
      (ExpenseListFilter.marketing, ExpenseCategory.marketing.label),
      (ExpenseListFilter.inventory, ExpenseCategory.inventory.label),
      (ExpenseListFilter.other, ExpenseCategory.other.label),
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

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        title: Text(expense.title),
        subtitle: Text(
          [expense.category.label, AppDateFormatter.display(expense.date)].join(' • '),
        ),
        trailing: Text(expense.amount.formatted),
      ),
    );
  }
}
