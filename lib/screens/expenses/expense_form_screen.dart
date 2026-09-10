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
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/expense.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/expense_provider.dart';
import 'package:provider/provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId});

  final String? expenseId;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _dateText = TextEditingController();
  final TextEditingController _description = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = AppDateFormatter.startOfDay(DateTime.now());
  String? _hydratedId;

  bool get _isEditing => widget.expenseId != null;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _dateText.dispose();
    _description.dispose();
    super.dispose();
  }

  void _hydrate(Expense expense) {
    if (_hydratedId == expense.id) return;
    _hydratedId = expense.id;
    _title.text = expense.title;
    _amount.text = expense.amount.format(includeSymbol: false);
    _category = expense.category;
    _date = AppDateFormatter.startOfDay(expense.date);
    _dateText.text = AppDateFormatter.display(_date);
    _description.text = expense.description;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _date = AppDateFormatter.startOfDay(picked);
      _dateText.text = AppDateFormatter.display(_date);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final business = context.read<BusinessProvider>().business;
    final expenses = context.read<ExpenseProvider>();
    if (business == null) {
      AppSnackbar.error(context, AppStrings.businessMissing);
      return;
    }
    try {
      final amount = Money.parse(_amount.text, currencyCode: business.currencyCode);
      await expenses.save(
        Expense(
          id: widget.expenseId ?? expenses.nextId(),
          businessId: business.id,
          title: _title.text.trim(),
          category: _category,
          amountMinor: amount.minorUnits,
          date: _date,
          description: _description.text.trim(),
          currencyCode: business.currencyCode,
        ),
      );
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.expenseSaved);
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final existing = widget.expenseId == null ? null : expenses.byId(widget.expenseId!);
    if (_isEditing && existing != null) {
      _hydrate(existing);
    }

    if (_isEditing && existing == null && !expenses.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editExpense)),
        body: const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    if (_dateText.text.isEmpty) {
      _dateText.text = AppDateFormatter.display(_date);
    }

    final busy = expenses.isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? AppStrings.editExpense : AppStrings.addExpense)),
      body: AppPaddedBody(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _title,
                  label: AppStrings.expenseTitleLabel,
                  enabled: !busy,
                  validator: AppValidators.name,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ExpenseCategory>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: AppStrings.expenseCategoryLabel),
                  items: [
                    for (final category in ExpenseCategory.values)
                      DropdownMenuItem(value: category, child: Text(category.label)),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _amount,
                  label: AppStrings.expenseAmountLabel,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: AppValidators.amount,
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _dateText,
                  label: AppStrings.expenseDateLabel,
                  readOnly: true,
                  enabled: !busy,
                  onTap: busy ? null : () => unawaited(_pickDate()),
                  prefixIcon: Icons.event_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _description,
                  label: AppStrings.expenseDescriptionLabel,
                  enabled: !busy,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: AppStrings.save,
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
