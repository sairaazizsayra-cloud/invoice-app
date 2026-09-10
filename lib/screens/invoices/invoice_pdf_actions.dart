import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/models/invoice.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/services/invoice_pdf_service.dart';
import 'package:invoice_pro/services/storage_service.dart';
import 'package:provider/provider.dart';

class InvoicePdfActions extends StatefulWidget {
  const InvoicePdfActions({super.key, required this.invoice});

  final Invoice invoice;

  @override
  State<InvoicePdfActions> createState() => _InvoicePdfActionsState();
}

class _InvoicePdfActionsState extends State<InvoicePdfActions> {
  bool _busy = false;

  InvoicePdfService _pdfOf(BuildContext context) {
    return InvoicePdfService(storage: context.read<StorageService>());
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AppException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.userMessage);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, AppStrings.pdfFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate({required bool upload}) async {
    final pdf = _pdfOf(context);
    final bytes = await pdf.build(widget.invoice);
    await pdf.saveLocal(widget.invoice, bytes);
    if (!upload) {
      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.pdfSaved);
      return;
    }
    try {
      final url = await pdf.upload(widget.invoice, bytes);
      if (!mounted) return;
      AppSnackbar.success(context, url == null ? AppStrings.pdfSaved : AppStrings.pdfUploaded);
    } on AppException {
      if (!mounted) return;
      AppSnackbar.error(context, AppStrings.pdfUploadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: AppStrings.invoicePdfSection),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: AppStrings.previewPdf,
                    icon: Icons.visibility_outlined,
                    variant: AppButtonVariant.tonal,
                    onPressed: _busy
                        ? null
                        : () => context.push(AppRoutes.invoicePdf(widget.invoice.id)),
                  ),
                  AppButton(
                    label: AppStrings.generatePdf,
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: _busy ? null : () => unawaited(_run(() => _generate(upload: true))),
                  ),
                  AppButton(
                    label: AppStrings.sharePdf,
                    icon: Icons.share_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: _busy
                        ? null
                        : () => unawaited(_run(() async {
                            final pdf = _pdfOf(context);
                            final bytes = await pdf.build(widget.invoice);
                            await pdf.share(widget.invoice, bytes);
                          })),
                  ),
                  AppButton(
                    label: AppStrings.printPdf,
                    icon: Icons.print_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: _busy
                        ? null
                        : () => unawaited(_run(() async {
                            final pdf = _pdfOf(context);
                            final bytes = await pdf.build(widget.invoice);
                            await pdf.print(widget.invoice, bytes);
                          })),
                  ),
                  AppButton(
                    label: AppStrings.savePdf,
                    icon: Icons.save_alt_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: _busy ? null : () => unawaited(_run(() => _generate(upload: false))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
