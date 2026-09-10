import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/customer.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/customer_provider.dart';
import 'package:provider/provider.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _company = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String? _hydratedId;
  bool get _isEditing => widget.customerId != null;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(Customer customer) {
    if (_hydratedId == customer.id) return;
    _hydratedId = customer.id;
    _name.text = customer.name;
    _company.text = customer.company;
    _email.text = customer.email;
    _phone.text = customer.phone;
    _address.text = customer.address;
    _city.text = customer.city;
    _notes.text = customer.notes;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final business = context.read<BusinessProvider>().business;
    final customers = context.read<CustomerProvider>();
    if (business == null) {
      AppSnackbar.error(context, AppStrings.businessMissing);
      return;
    }

    final existing = widget.customerId == null ? null : customers.byId(widget.customerId!);
    final draft = Customer(
      id: existing?.id ?? customers.nextId(),
      businessId: business.id,
      name: _name.text.trim(),
      company: _company.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      notes: _notes.text.trim(),
    );

    try {
      await customers.save(draft);
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.customerSaved);
      context.pop(draft);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>();
    final existing = widget.customerId == null ? null : customers.byId(widget.customerId!);
    if (_isEditing && existing != null) {
      _hydrate(existing);
    }

    if (_isEditing && existing == null && !customers.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editCustomer)),
        body: const AppErrorState(title: AppStrings.pageNotFound),
      );
    }

    final busy = customers.isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? AppStrings.editCustomer : AppStrings.addCustomer)),
      body: AppPaddedBody(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  label: AppStrings.customerNameLabel,
                  enabled: !busy,
                  validator: AppValidators.name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _company,
                  label: AppStrings.companyLabel,
                  enabled: !busy,
                  validator: AppValidators.optionalName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _email,
                  label: AppStrings.emailLabel,
                  enabled: !busy,
                  validator: AppValidators.optionalEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: AppStrings.phoneLabel,
                  enabled: !busy,
                  validator: AppValidators.optionalPhone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _address,
                  label: AppStrings.addressLabel,
                  enabled: !busy,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _city,
                  label: AppStrings.cityLabel,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _notes,
                  label: AppStrings.notesLabel,
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
