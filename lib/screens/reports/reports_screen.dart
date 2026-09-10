import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/routes/app_routes.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reportsTitle)),
      body: AppPaddedBody(
        child: ListView(
          children: [
            Text(AppStrings.reportsSubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ReportTile(
                    icon: Icons.trending_up_rounded,
                    title: AppStrings.salesReportTitle,
                    subtitle: AppStrings.salesReportSubtitle,
                    onTap: () => context.push(AppRoutes.report(ReportKind.sales)),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.receipt_long_outlined,
                    title: AppStrings.invoiceReportTitle,
                    subtitle: AppStrings.invoiceReportSubtitle,
                    onTap: () => context.push(AppRoutes.report(ReportKind.invoices)),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.groups_outlined,
                    title: AppStrings.customerReportTitle,
                    subtitle: AppStrings.customerReportSubtitle,
                    onTap: () => context.push(AppRoutes.report(ReportKind.customers)),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.inventory_2_outlined,
                    title: AppStrings.productReportTitle,
                    subtitle: AppStrings.productReportSubtitle,
                    onTap: () => context.push(AppRoutes.report(ReportKind.products)),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: AppStrings.expenseReportTitle,
                    subtitle: AppStrings.expenseReportSubtitle,
                    onTap: () => context.push(AppRoutes.report(ReportKind.expenses)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
