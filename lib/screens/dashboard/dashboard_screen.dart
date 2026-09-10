import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_colors.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/responsive.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_search_field.dart';
import 'package:invoice_pro/core/widgets/app_stat_card.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/core/widgets/app_status_chip.dart';
import 'package:invoice_pro/core/widgets/date_filter_chips.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/providers/business_provider.dart';
import 'package:invoice_pro/providers/dashboard_provider.dart';
import 'package:invoice_pro/providers/expense_provider.dart';
import 'package:invoice_pro/providers/invoice_provider.dart';
import 'package:invoice_pro/providers/notification_provider.dart';
import 'package:invoice_pro/providers/payment_provider.dart';
import 'package:invoice_pro/repositories/dashboard_repository.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/screens/dashboard/dashboard_charts.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessProvider>();
    final business = businessState.business;

    if (businessState.isLoading && business == null) {
      return const Scaffold(body: AppLoading(message: AppStrings.loading));
    }
    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.navDashboard)),
        body: const AppErrorState(title: AppStrings.businessMissing),
      );
    }

    // Keep one DashboardProvider per business — avoid recreating on every list length change.
    return ChangeNotifierProvider(
      key: ValueKey(business.id),
      create: (context) => DashboardProvider(context.read<DashboardRepository>())..load(business),
      child: _DashboardCatalogListener(business: business),
    );
  }
}

class _DashboardCatalogListener extends StatefulWidget {
  const _DashboardCatalogListener({required this.business});

  final Business business;

  @override
  State<_DashboardCatalogListener> createState() => _DashboardCatalogListenerState();
}

class _DashboardCatalogListenerState extends State<_DashboardCatalogListener> {
  Timer? _debounce;
  int _lastSignature = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signature =
        context.watch<InvoiceProvider>().allInvoices.length +
        context.watch<PaymentProvider>().allPayments.length * 1000 +
        context.watch<ExpenseProvider>().allExpenses.length * 1000000;
    if (_lastSignature == 0) {
      _lastSignature = signature;
      return;
    }
    if (signature == _lastSignature) return;
    _lastSignature = signature;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      unawaited(context.read<DashboardProvider>().load(widget.business));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DashboardBody(business: widget.business);
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.business});

  final Business business;

  Future<void> _onFilterSelected(BuildContext context, DateFilterPreset preset) async {
    final dashboard = context.read<DashboardProvider>();
    if (preset == DateFilterPreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: dashboard.range.start, end: dashboard.range.end),
      );
      if (picked == null || !context.mounted) return;
      await dashboard.setPreset(
        preset,
        business,
        customRange: DateRange(
          start: AppDateFormatter.startOfDay(picked.start),
          end: AppDateFormatter.endOfDay(picked.end),
        ),
      );
      return;
    }
    await dashboard.setPreset(preset, business);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final dashboard = context.watch<DashboardProvider>();
    final snapshot = dashboard.snapshot;
    final semantic = AppSemanticColors.of(context);
    final columns = Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 3);
    final unread = context.watch<NotificationProvider>().unreadCount;
    final greeting = (profile != null && profile.name.trim().isNotEmpty)
        ? 'Welcome, ${profile.name.trim()}'
        : AppStrings.dashboardGreeting;

    final stats = <(String, String, IconData, Color)>[
      (AppStrings.totalRevenue, snapshot.revenue.formatted, Icons.payments_outlined, semantic.success),
      (AppStrings.totalInvoices, '${snapshot.invoiceCount}', Icons.receipt_long_outlined, Theme.of(context).colorScheme.primary),
      (AppStrings.paidInvoices, '${snapshot.paidCount}', Icons.check_circle_outline, semantic.success),
      (AppStrings.unpaidInvoices, '${snapshot.unpaidCount}', Icons.schedule_outlined, semantic.warning),
      (AppStrings.overdueInvoices, '${snapshot.overdueCount}', Icons.warning_amber_rounded, semantic.overdue),
      (AppStrings.totalCustomers, '${snapshot.customerCount}', Icons.groups_outlined, semantic.info),
      (AppStrings.totalProducts, '${snapshot.productCount}', Icons.inventory_2_outlined, Theme.of(context).colorScheme.tertiary),
      (AppStrings.totalExpenses, snapshot.expenses.formatted, Icons.account_balance_wallet_outlined, semantic.warning),
      (AppStrings.netProfit, snapshot.netProfit.formatted, Icons.trending_up_rounded, semantic.success),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navDashboard),
        actions: [
          IconButton(
            tooltip: AppStrings.notificationsTitle,
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: AppStrings.reportsTitle,
            onPressed: () => context.push(AppRoutes.reports),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.load(business),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: Responsive.pagePadding(context),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      business.name.isEmpty ? AppStrings.dashboardLiveSubtitle : business.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DateFilterChips(
                      selected: dashboard.preset,
                      onSelected: (preset) => unawaited(_onFilterSelected(context, preset)),
                    ),
                    if (dashboard.preset == DateFilterPreset.custom) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${AppDateFormatter.display(dashboard.range.start)} – ${AppDateFormatter.display(dashboard.range.end)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (dashboard.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppErrorState(title: dashboard.error!, onRetry: () => dashboard.load(business)),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = AppSpacing.md;
                        final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final stat in stats)
                              SizedBox(
                                width: itemWidth,
                                height: 128,
                                child: AppStatCard(
                                  label: stat.$1,
                                  value: stat.$2,
                                  icon: stat.$3,
                                  accent: stat.$4,
                                  onTap: stat.$1 == AppStrings.totalExpenses
                                      ? () => context.push(AppRoutes.expenses)
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    DashboardSeriesChart.line(title: AppStrings.revenueChart, points: snapshot.revenueSeries),
                    const SizedBox(height: AppSpacing.xl),
                    DashboardSeriesChart.bar(title: AppStrings.monthlySales, points: snapshot.salesSeries),
                    const SizedBox(height: AppSpacing.xl),
                    const AppSectionHeader(title: AppStrings.recentInvoices),
                    _RecentInvoices(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.xl),
                    const AppSectionHeader(title: AppStrings.recentPayments),
                    _RecentPayments(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.xl),
                    const AppSectionHeader(title: AppStrings.topCustomers),
                    _NamedTotals(
                      items: snapshot.topCustomers,
                      emptyTitle: AppStrings.emptyTopCustomersTitle,
                      emptyBody: AppStrings.emptyTopCustomersBody,
                      icon: Icons.groups_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const AppSectionHeader(title: AppStrings.topProducts),
                    _NamedTotals(
                      items: snapshot.topProducts,
                      emptyTitle: AppStrings.emptyTopProductsTitle,
                      emptyBody: AppStrings.emptyTopProductsBody,
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInvoices extends StatelessWidget {
  const _RecentInvoices({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.recentInvoices.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyRecentInvoicesTitle,
          message: AppStrings.emptyRecentInvoicesBody,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final invoice in snapshot.recentInvoices)
            ListTile(
              title: Text(invoice.number),
              subtitle: Text(invoice.customerName),
              trailing: Text(invoice.total.formatted),
              leading: AppStatusChip(status: invoice.status),
              onTap: () => context.push(AppRoutes.invoiceDetail(invoice.id)),
            ),
        ],
      ),
    );
  }
}

class _RecentPayments extends StatelessWidget {
  const _RecentPayments({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.recentPayments.isEmpty) {
      return const AppCard(
        child: AppEmptyState(
          title: AppStrings.emptyPaymentsTitle,
          message: AppStrings.emptyPaymentsBody,
          icon: Icons.payments_outlined,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final payment in snapshot.recentPayments)
            ListTile(
              title: Text(payment.amount.formatted),
              subtitle: Text(
                [
                  if (payment.customerName.isNotEmpty) payment.customerName,
                  if (payment.invoiceNumber.isNotEmpty) payment.invoiceNumber,
                  AppDateFormatter.display(payment.paidAt),
                ].join(' • '),
              ),
              onTap: payment.invoiceId.isEmpty
                  ? null
                  : () => context.push(AppRoutes.invoiceDetail(payment.invoiceId)),
            ),
        ],
      ),
    );
  }
}

class _NamedTotals extends StatelessWidget {
  const _NamedTotals({
    required this.items,
    required this.emptyTitle,
    required this.emptyBody,
    required this.icon,
  });

  final List<NamedMoneyTotal> items;
  final String emptyTitle;
  final String emptyBody;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(
        child: AppEmptyState(title: emptyTitle, message: emptyBody, icon: icon),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final item in items)
            ListTile(
              title: Text(item.name),
              trailing: Text(item.total.formatted),
            ),
        ],
      ),
    );
  }
}
