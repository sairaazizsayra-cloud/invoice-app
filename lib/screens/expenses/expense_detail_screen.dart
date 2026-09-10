import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/providers/expense_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:provider/provider.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  Future<void> _delete(BuildContext context, Expense expense) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteExpenseTitle,
      message: AppStrings.deleteExpenseBody,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<ExpenseProvider>().delete(expense);
      if (!context.mounted) return;
      AppSnackbar.success(context, AppStrings.expenseDeleted);
      context.pop();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final expense = expenses.byId(expenseId);

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.expenseDetails)),
        body: expenses.isLoading
            ? const AppLoading(message: AppStrings.loading)
            : const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.expenseDetails),
        actions: [
          IconButton(
            tooltip: AppStrings.editExpense,
            onPressed: () => context.push(AppRoutes.expenseEdit(expense.id)),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: AppStrings.delete,
            onPressed: expenses.isSaving ? null : () => unawaited(_delete(context, expense)),
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
                    Text(expense.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(expense.category.label, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(AppStrings.expenseAmountLabel),
                      trailing: Text(expense.amount.formatted),
                    ),
                    ListTile(
                      title: const Text(AppStrings.expenseDateLabel),
                      trailing: Text(AppDateFormatter.display(expense.date)),
                    ),
                    ListTile(
                      title: const Text(AppStrings.expenseCategoryLabel),
                      trailing: Text(expense.category.label),
                    ),
                  ],
                ),
              ),
              if (expense.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.expenseDescriptionLabel, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(expense.description),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
