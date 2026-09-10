import 'package:invoice_pro/core/utils/date_formatter.dart';
import 'package:invoice_pro/core/utils/money.dart';
import 'package:invoice_pro/models/app_user.dart';
import 'package:invoice_pro/models/invoice_status.dart';

class InvoiceLineRecord {
  const InvoiceLineRecord({
    required this.productId,
    required this.name,
    required this.lineTotal,
    required this.quantity,
  });

  final String productId;
  final String name;
  final Money lineTotal;
  final int quantity;

  factory InvoiceLineRecord.fromMap(Map<String, dynamic> data, {required String currencyCode}) {
    return InvoiceLineRecord(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? 'Item',
      lineTotal: Money.fromMinorUnits(
        (data['lineTotalMinor'] as num?)?.toInt() ?? 0,
        currencyCode: currencyCode,
      ),
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.total,
    required this.paid,
    required this.lines,
    this.issueDate,
    this.dueDate,
  });

  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final InvoiceStatus status;
  final Money total;
  final Money paid;
  final List<InvoiceLineRecord> lines;
  final DateTime? issueDate;
  final DateTime? dueDate;

  Money get outstanding => total - paid;

  bool get isCancelled => status == InvoiceStatus.cancelled;
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isSettled => !isCancelled && (status == InvoiceStatus.paid || !outstanding.isPositive);

  bool isOverdue(DateTime now) {
    if (isCancelled || isSettled) return false;
    if (status == InvoiceStatus.overdue) return true;
    if (dueDate == null) return false;
    return AppDateFormatter.startOfDay(dueDate!).isBefore(AppDateFormatter.startOfDay(now));
  }

  factory InvoiceRecord.fromMap(String id, Map<String, dynamic> data, {required String currencyCode}) {
    final rawLines = data['items'] ?? data['lines'];
    final lines = <InvoiceLineRecord>[];
    if (rawLines is List) {
      for (final item in rawLines) {
        if (item is Map) {
          lines.add(
            InvoiceLineRecord.fromMap(Map<String, dynamic>.from(item), currencyCode: currencyCode),
          );
        }
      }
    }

    return InvoiceRecord(
      id: id,
      number: data['invoiceNumber'] as String? ?? id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      status: InvoiceStatusX.fromStorage(data['status'] as String?),
      total: Money.fromMinorUnits(
        (data['totalMinor'] as num?)?.toInt() ?? 0,
        currencyCode: currencyCode,
      ),
      paid: Money.fromMinorUnits(
        (data['paidMinor'] as num?)?.toInt() ?? 0,
        currencyCode: currencyCode,
      ),
      lines: lines,
      issueDate: AppUser.dateTimeFrom(data['issueDate']) ?? AppUser.dateTimeFrom(data['invoiceDate']),
      dueDate: AppUser.dateTimeFrom(data['dueDate']),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.customerId = '',
    this.customerName = '',
    this.invoiceId = '',
    this.invoiceNumber = '',
    this.method = '',
  });

  final String id;
  final Money amount;
  final DateTime paidAt;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final String invoiceNumber;
  final String method;

  factory PaymentRecord.fromMap(String id, Map<String, dynamic> data, {required String currencyCode}) {
    return PaymentRecord(
      id: id,
      amount: Money.fromMinorUnits(
        (data['amountMinor'] as num?)?.toInt() ?? 0,
        currencyCode: currencyCode,
      ),
      paidAt: AppUser.dateTimeFrom(data['paidAt']) ??
          AppUser.dateTimeFrom(data['date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      method: data['method'] as String? ?? '',
    );
  }
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.title = '',
    this.category = '',
  });

  final String id;
  final Money amount;
  final DateTime date;
  final String title;
  final String category;

  factory ExpenseRecord.fromMap(String id, Map<String, dynamic> data, {required String currencyCode}) {
    return ExpenseRecord(
      id: id,
      amount: Money.fromMinorUnits(
        (data['amountMinor'] as num?)?.toInt() ?? 0,
        currencyCode: currencyCode,
      ),
      date: AppUser.dateTimeFrom(data['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
    );
  }
}

class NamedMoneyTotal {
  const NamedMoneyTotal({required this.id, required this.name, required this.total});

  final String id;
  final String name;
  final Money total;
}

class ChartPoint {
  const ChartPoint({required this.label, required this.amount, required this.sortKey});

  final String label;
  final Money amount;
  final DateTime sortKey;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.revenue,
    required this.expenses,
    required this.netProfit,
    required this.invoiceCount,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.customerCount,
    required this.productCount,
    required this.revenueSeries,
    required this.salesSeries,
    required this.recentInvoices,
    required this.recentPayments,
    required this.topCustomers,
    required this.topProducts,
  });

  final Money revenue;
  final Money expenses;
  final Money netProfit;
  final int invoiceCount;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final int customerCount;
  final int productCount;
  final List<ChartPoint> revenueSeries;
  final List<ChartPoint> salesSeries;
  final List<InvoiceRecord> recentInvoices;
  final List<PaymentRecord> recentPayments;
  final List<NamedMoneyTotal> topCustomers;
  final List<NamedMoneyTotal> topProducts;

  factory DashboardSnapshot.empty({String currencyCode = 'PKR'}) {
    final zero = Money.zero(currencyCode: currencyCode);
    return DashboardSnapshot(
      revenue: zero,
      expenses: zero,
      netProfit: zero,
      invoiceCount: 0,
      paidCount: 0,
      unpaidCount: 0,
      overdueCount: 0,
      customerCount: 0,
      productCount: 0,
      revenueSeries: const [],
      salesSeries: const [],
      recentInvoices: const [],
      recentPayments: const [],
      topCustomers: const [],
      topProducts: const [],
    );
  }
}
