import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/core/utils/validators.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_text_field.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:provider/provider.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  static const List<String> _currencies = ['PKR', 'USD', 'EUR', 'GBP'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _ownerName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _taxNumber = TextEditingController();
  final TextEditingController _taxPercent = TextEditingController();
  final TextEditingController _invoicePrefix = TextEditingController();
  final TextEditingController _paymentInstructions = TextEditingController();
  final TextEditingController _terms = TextEditingController();

  String _currencyCode = AppConstants.defaultCurrencyCode;
  String? _logoUrl;
  String? _hydratedId;
  bool _uploadingLogo = false;

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _website.dispose();
    _taxNumber.dispose();
    _taxPercent.dispose();
    _invoicePrefix.dispose();
    _paymentInstructions.dispose();
    _terms.dispose();
    super.dispose();
  }

  void _hydrate(Business business) {
    if (_hydratedId == business.id) return;
    _hydratedId = business.id;
    _name.text = business.name;
    _ownerName.text = business.ownerName;
    _email.text = business.email;
    _phone.text = business.phone;
    _address.text = business.address;
    _city.text = business.city;
    _website.text = business.website;
    _taxNumber.text = business.taxNumber;
    _taxPercent.text = Money.fromMinorUnits(business.defaultTaxPercentMinor).format(includeSymbol: false);
    _invoicePrefix.text = business.invoicePrefix;
    _paymentInstructions.text = business.paymentInstructions;
    _terms.text = business.termsAndConditions;
    _currencyCode = _currencies.contains(business.currencyCode)
        ? business.currencyCode
        : AppConstants.defaultCurrencyCode;
    _logoUrl = business.logoUrl;
  }

  Future<void> _save(Business current) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final tax = Money.parse(_taxPercent.text);
    final updated = current.copyWith(
      name: _name.text.trim(),
      ownerName: _ownerName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      website: _website.text.trim(),
      taxNumber: _taxNumber.text.trim(),
      currencyCode: _currencyCode,
      defaultTaxPercentMinor: tax.minorUnits,
      invoicePrefix: _invoicePrefix.text.trim(),
      paymentInstructions: _paymentInstructions.text.trim(),
      termsAndConditions: _terms.text.trim(),
      logoUrl: _logoUrl,
    );
    try {
      await context.read<BusinessProvider>().save(updated);
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.businessSaved);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    }
  }

  Future<void> _pickLogo(Business business) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.imagePickMaxDimension,
      maxHeight: AppConstants.imagePickMaxDimension,
      imageQuality: AppConstants.imagePickQuality,
    );
    if (picked == null || !mounted) return;
    final businesses = context.read<BusinessProvider>();
    setState(() => _uploadingLogo = true);
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final url = await businesses.uploadLogo(
        businessId: business.id,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() => _logoUrl = url);
      await businesses.save(business.copyWith(logoUrl: url));
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.logoUpdated);
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, AppStrings.logoUploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final business = provider.business;

    if (provider.isLoading && business == null) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.businessProfileTitle)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    _hydrate(business);
    final busy = provider.isSaving || _uploadingLogo;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.businessProfileTitle)),
      body: AppPaddedBody(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                AppStrings.businessProfileSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: _logoUrl == null ? null : NetworkImage(_logoUrl!),
                      child: _logoUrl == null
                          ? Icon(
                              Icons.storefront_outlined,
                              size: 36,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: busy ? null : () => unawaited(_pickLogo(business)),
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(_uploadingLogo ? AppStrings.loading : AppStrings.pickLogo),
                    ),
                  ],
                ),
              ),
              AppTextField(
                controller: _name,
                label: AppStrings.businessNameLabel,
                enabled: !busy,
                validator: AppValidators.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _ownerName,
                label: AppStrings.ownerNameLabel,
                enabled: !busy,
                validator: AppValidators.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _email,
                label: AppStrings.emailLabel,
                enabled: !busy,
                validator: AppValidators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phone,
                label: AppStrings.phoneLabel,
                enabled: !busy,
                validator: AppValidators.phone,
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
                controller: _website,
                label: AppStrings.websiteLabel,
                enabled: !busy,
                validator: AppValidators.optionalWebsite,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _taxNumber,
                label: AppStrings.taxNumberLabel,
                enabled: !busy,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _currencyCode,
                decoration: const InputDecoration(labelText: AppStrings.currencyLabel),
                items: [
                  for (final code in _currencies)
                    DropdownMenuItem(value: code, child: Text(code == 'PKR' ? 'PKR (Rs)' : code)),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _currencyCode = value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _taxPercent,
                label: AppStrings.defaultTaxLabel,
                enabled: !busy,
                validator: AppValidators.taxPercent,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _invoicePrefix,
                label: AppStrings.invoicePrefixLabel,
                enabled: !busy,
                validator: AppValidators.invoicePrefix,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _paymentInstructions,
                label: AppStrings.paymentInstructionsLabel,
                enabled: !busy,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _terms,
                label: AppStrings.termsLabel,
                enabled: !busy,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: AppStrings.save,
                expanded: true,
                isLoading: provider.isSaving,
                onPressed: busy ? null : () => unawaited(_save(business)),
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
