import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> load({
    required Business business,
    required DateRange range,
    required DateTime now,
  });
}
