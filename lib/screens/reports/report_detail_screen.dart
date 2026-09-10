import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/errors/app_exception.dart';
import 'package:invoice_pro/core/theme/app_colors.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/report_calculator.dart';
import 'package:invoice_pro/core/utils/responsive.dart';
import 'package:invoice_pro/core/widgets/app_button.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_feedback.dart';
import 'package:invoice_pro/core/widgets/app_page.dart';
import 'package:invoice_pro/core/widgets/app_stat_card.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/date_filter_chips.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/expense_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/dashboard/dashboard_charts.dart';
import 'package:invoice_pro/services/report_pdf_service.dart';
import 'package:provider/provider.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.kind});

  final ReportKind kind;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  DateFilterPreset _preset = DateFilterPreset.thisMonth;
  late DateRange _range = DateRange.fromPreset(_preset);
  InvoiceReportFilter _invoiceFilter = InvoiceReportFilter.all;
  bool _busy = false;

  String get _title {
    switch (widget.kind) {
      case ReportKind.sales:
        return AppStrings.salesReportTitle;
      case ReportKind.invoices:
        return AppStrings.invoiceReportTitle;
      case ReportKind.customers:
        return AppStrings.customerReportTitle;
      case ReportKind.products:
        return AppStrings.productReportTitle;
      case ReportKind.expenses:
        return AppStrings.expenseReportTitle;
    }
  }

  Future<void> _setPreset(DateFilterPreset preset) async {
    if (preset == DateFilterPreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _range.start, end: _range.end),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _preset = preset;
        _range = DateRange(
          start: AppDateFormatter.startOfDay(picked.start),
          end: AppDateFormatter.endOfDay(picked.end),
        );
      });
      return;
    }
    setState(() {
      _preset = preset;
      _range = DateRange.fromPreset(preset);
    });
  }

  ReportSnapshot _snapshot() {
    final invoices = context.read<InvoiceProvider>();
    final payments = context.read<PaymentProvider>();
    final expenses = context.read<ExpenseProvider>();
    final business = context.read<BusinessProvider>().business;
    return ReportCalculator.calculate(
      range: _range,
      now: DateTime.now(),
      currencyCode: business?.currencyCode ?? AppConstants.defaultCurrencyCode,
      invoices: [for (final invoice in invoices.allInvoices) invoice.toRecord()],
      payments: [for (final payment in payments.allPayments) payment.toRecord()],
      expenses: [for (final expense in expenses.allExpenses) expense.toRecord()],
    );
  }

  ReportPdfArgs _pdfArgs(ReportSnapshot snapshot) {
    final business = context.read<BusinessProvider>().business;
    return ReportPdfArgs(
      kind: widget.kind,
      snapshot: snapshot,
      businessName: business?.name ?? AppStrings.appName,
    );
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

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final invoices = context.watch<InvoiceProvider>();
    context.watch<PaymentProvider>();
    context.watch<ExpenseProvider>();
    final business = businessState.business;

    if ((businessState.isLoading && business == null) || invoices.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const AppLoading(message: AppStrings.loading),
      );
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    final snapshot = _snapshot();
    final semantic = AppSemanticColors.of(context);
    final columns = Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 3);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: AppPaddedBody(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateFilterChips(selected: _preset, onSelected: (preset) => unawaited(_setPreset(preset))),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${AppDateFormatter.display(_range.start)} – ${AppDateFormatter.display(_range.end)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExportBar(
                busy: _busy,
                onPreview: () => context.push(AppRoutes.reportPdf(widget.kind), extra: _pdfArgs(snapshot)),
                onShare: () => unawaited(_run(() async {
                  final pdf = ReportPdfService();
                  final content = pdf.contentFor(
                    kind: widget.kind,
                    snapshot: snapshot,
                    businessName: business.name,
                  );
                  await pdf.share(content, await pdf.build(content));
                })),
                onPrint: () => unawaited(_run(() async {
                  final pdf = ReportPdfService();
                  final content = pdf.contentFor(
                    kind: widget.kind,
                    snapshot: snapshot,
                    businessName: business.name,
                  );
                  await pdf.print(content, await pdf.build(content));
                })),
                onSave: () => unawaited(_run(() async {
                  final pdf = ReportPdfService();
                  final content = pdf.contentFor(
                    kind: widget.kind,
                    snapshot: snapshot,
                    businessName: business.name,
                  );
                  await pdf.saveLocal(content, await pdf.build(content));
                  if (!context.mounted) return;
                  AppSnackbar.success(context, AppStrings.reportPdfSaved);
                })),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: AppSpacing.xl),
              _StatsGrid(columns: columns, items: _stats(snapshot, semantic)),
              const SizedBox(height: AppSpacing.xl),
              ..._body(context, snapshot),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  List<(String, String, IconData, Color)> _stats(ReportSnapshot snapshot, AppSemanticColors semantic) {
    switch (widget.kind) {
      case ReportKind.sales:
        return [
          (AppStrings.totalRevenue, snapshot.revenue.formatted, Icons.payments_outlined, semantic.success),
          (AppStrings.reportBilled, snapshot.billed.formatted, Icons.receipt_long_outlined, Theme.of(context).colorScheme.primary),
          (AppStrings.totalExpenses, snapshot.expenses.formatted, Icons.account_balance_wallet_outlined, semantic.warning),
          (AppStrings.netProfit, snapshot.netProfit.formatted, Icons.trending_up_rounded, semantic.success),
        ];
      case ReportKind.invoices:
        return [
          (AppStrings.paidInvoices, '${snapshot.paid.count}', Icons.check_circle_outline, semantic.success),
          (AppStrings.unpaidInvoices, '${snapshot.unpaid.count}', Icons.schedule_outlined, semantic.warning),
          (AppStrings.overdueInvoices, '${snapshot.overdue.count}', Icons.warning_amber_rounded, semantic.overdue),
          (AppStrings.filterCancelled, '${snapshot.cancelled.count}', Icons.cancel_outlined, Theme.of(context).colorScheme.error),
        ];
      case ReportKind.customers:
        return [
          (AppStrings.totalCustomers, '${snapshot.customers.length}', Icons.groups_outlined, semantic.info),
          (AppStrings.reportBilled, snapshot.billed.formatted, Icons.payments_outlined, semantic.success),
        ];
      case ReportKind.products:
        return [
          (AppStrings.totalProducts, '${snapshot.products.length}', Icons.inventory_2_outlined, Theme.of(context).colorScheme.tertiary),
          (AppStrings.reportBilled, snapshot.billed.formatted, Icons.payments_outlined, semantic.success),
        ];
      case ReportKind.expenses:
        return [
          (AppStrings.totalExpenses, snapshot.expenses.formatted, Icons.account_balance_wallet_outlined, semantic.warning),
          (AppStrings.reportCount, '${snapshot.expenseRows.length}', Icons.list_alt_outlined, Theme.of(context).colorScheme.primary),
        ];
    }
  }

  List<Widget> _body(BuildContext context, ReportSnapshot snapshot) {
    switch (widget.kind) {
      case ReportKind.sales:
        final points = snapshot.revenueSeries.any((point) => !point.amount.isZero)
            ? snapshot.revenueSeries
            : snapshot.salesSeries;
        return [
          DashboardSeriesChart.line(title: AppStrings.revenueChart, points: points),
          const SizedBox(height: AppSpacing.xl),
          DashboardSeriesChart.bar(title: AppStrings.monthlySales, points: snapshot.salesSeries),
        ];
      case ReportKind.invoices:
        return [
          _InvoiceFilterBar(selected: _invoiceFilter, onSelected: (value) => setState(() => _invoiceFilter = value)),
          const SizedBox(height: AppSpacing.md),
          _InvoiceTable(invoices: _filteredInvoices(snapshot)),
        ];
      case ReportKind.customers:
        return [_CustomerTable(rows: snapshot.customers)];
      case ReportKind.products:
        return [_ProductTable(rows: snapshot.products)];
      case ReportKind.expenses:
        final categoryPoints = [
          for (final category in snapshot.expenseCategories)
            ChartPoint(label: category.category, amount: category.total, sortKey: DateTime(2000)),
        ];
        return [
          DashboardSeriesChart.bar(title: AppStrings.expenseReportTitle, points: categoryPoints),
          const SizedBox(height: AppSpacing.xl),
          _ExpenseTable(rows: snapshot.expenseRows),
        ];
    }
  }

  List<InvoiceRecord> _filteredInvoices(ReportSnapshot snapshot) {
    final now = DateTime.now();
    switch (_invoiceFilter) {
      case InvoiceReportFilter.all:
        return snapshot.invoices;
      case InvoiceReportFilter.paid:
        return snapshot.invoices.where((invoice) => !invoice.isDraft && !invoice.isCancelled && invoice.isSettled).toList();
      case InvoiceReportFilter.unpaid:
        return snapshot.invoices.where((invoice) {
          return !invoice.isDraft && !invoice.isCancelled && !invoice.isSettled && !invoice.isOverdue(now);
        }).toList();
      case InvoiceReportFilter.overdue:
        return snapshot.invoices.where((invoice) => invoice.isOverdue(now)).toList();
      case InvoiceReportFilter.cancelled:
        return snapshot.invoices.where((invoice) => invoice.isCancelled).toList();
    }
  }
}

class _ExportBar extends StatelessWidget {
  const _ExportBar({
    required this.busy,
    required this.onPreview,
    required this.onShare,
    required this.onPrint,
    required this.onSave,
  });

  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onShare;
  final VoidCallback onPrint;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton(
          label: AppStrings.previewPdf,
          icon: Icons.visibility_outlined,
          variant: AppButtonVariant.tonal,
          onPressed: busy ? null : onPreview,
        ),
        AppButton(
          label: AppStrings.sharePdf,
          icon: Icons.share_outlined,
          variant: AppButtonVariant.outlined,
          onPressed: busy ? null : onShare,
        ),
        AppButton(
          label: AppStrings.printPdf,
          icon: Icons.print_outlined,
          variant: AppButtonVariant.outlined,
          onPressed: busy ? null : onPrint,
        ),
        AppButton(
          label: AppStrings.savePdf,
          icon: Icons.save_alt_outlined,
          variant: AppButtonVariant.outlined,
          onPressed: busy ? null : onSave,
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.columns, required this.items});

  final int columns;
  final List<(String, String, IconData, Color)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in items)
              SizedBox(
                width: itemWidth,
                height: 128,
                child: AppStatCard(label: stat.$1, value: stat.$2, icon: stat.$3, accent: stat.$4),
              ),
          ],
        );
      },
    );
  }
}

class _InvoiceFilterBar extends StatelessWidget {
  const _InvoiceFilterBar({required this.selected, required this.onSelected});

  final InvoiceReportFilter selected;
  final ValueChanged<InvoiceReportFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(InvoiceReportFilter, String)>[
      (InvoiceReportFilter.all, AppStrings.filterAll),
      (InvoiceReportFilter.paid, AppStrings.paidInvoices),
      (InvoiceReportFilter.unpaid, AppStrings.unpaidInvoices),
      (InvoiceReportFilter.overdue, AppStrings.overdueInvoices),
      (InvoiceReportFilter.cancelled, AppStrings.filterCancelled),
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

class _InvoiceTable extends StatelessWidget {
  const _InvoiceTable({required this.invoices});

  final List<InvoiceRecord> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyReportTitle,
          message: AppStrings.emptyReportBody,
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
              subtitle: Text(invoice.customerName),
              trailing: Text(invoice.total.formatted),
              onTap: () => context.push(AppRoutes.invoiceDetail(invoice.id)),
            ),
        ],
      ),
    );
  }
}

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({required this.rows});

  final List<CustomerReportRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyReportTitle,
          message: AppStrings.emptyReportBody,
          icon: Icons.groups_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              title: Text(row.name),
              subtitle: Text('${row.invoiceCount} · ${row.billed.formatted}'),
              trailing: Text(row.outstanding.formatted),
              onTap: () => context.push(AppRoutes.customerDetail(row.id)),
            ),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  const _ProductTable({required this.rows});

  final List<ProductReportRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyReportTitle,
          message: AppStrings.emptyReportBody,
          icon: Icons.inventory_2_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              title: Text(row.name),
              subtitle: Text('${AppStrings.quantityLabel}: ${row.quantity}'),
              trailing: Text(row.total.formatted),
              onTap: () => context.push(AppRoutes.productDetail(row.id)),
            ),
        ],
      ),
    );
  }
}

class _ExpenseTable extends StatelessWidget {
  const _ExpenseTable({required this.rows});

  final List<ExpenseRecord> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyReportTitle,
          message: AppStrings.emptyReportBody,
          icon: Icons.account_balance_wallet_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              title: Text(row.title.isEmpty ? row.category : row.title),
              subtitle: Text(
                [if (row.category.isNotEmpty) row.category, AppDateFormatter.display(row.date)].join(' • '),
              ),
              trailing: Text(row.amount.formatted),
              onTap: () => context.push(AppRoutes.expenseDetail(row.id)),
            ),
        ],
      ),
    );
  }
}
