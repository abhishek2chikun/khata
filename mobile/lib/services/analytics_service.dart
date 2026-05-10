import '../models/analytics.dart';

abstract class AnalyticsService {
  Future<Dashboard> getDashboard({String? fromDate, String? toDate});
}
