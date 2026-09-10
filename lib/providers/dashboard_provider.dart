import 'package:flutter/foundation.dart';
import 'package:invoice_pro/core/utils/app_logger.dart';
import 'package:invoice_pro/models/business.dart';
import 'package:invoice_pro/models/dashboard_models.dart';
import 'package:invoice_pro/models/date_range.dart';
import 'package:invoice_pro/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  final DashboardRepository _repository;

  DateFilterPreset _preset = DateFilterPreset.thisMonth;
  DateRange _range = DateRange.fromPreset(DateFilterPreset.thisMonth);
  DashboardSnapshot _snapshot = DashboardSnapshot.empty();
  bool _loading = false;
  String? _error;
  String? _businessId;

  DateFilterPreset get preset => _preset;
  DateRange get range => _range;
  DashboardSnapshot get snapshot => _snapshot;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load(Business business) async {
    _businessId = business.id;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load(
        business: business,
        range: _range,
        now: DateTime.now(),
      );
    } catch (error, stack) {
      AppLogger.error('Dashboard load failed', error, stack);
      _error = 'Could not load dashboard data.';
      _snapshot = DashboardSnapshot.empty(currencyCode: business.currencyCode);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setPreset(DateFilterPreset preset, Business business, {DateRange? customRange}) async {
    _preset = preset;
    _range = customRange ?? DateRange.fromPreset(preset);
    await load(business);
  }

  bool belongsTo(String? businessId) => _businessId == businessId;
}
