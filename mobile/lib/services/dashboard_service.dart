import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  Future<DashboardModel> getMetrics({String? targetDate}) async {
    final Map<String, String> query = {};
    if (targetDate != null) query['target_date'] = targetDate;

    final response = await ApiClient.get(ApiConstants.dashboardMetrics, queryParams: query);
    return DashboardModel.fromJson(response as Map<String, dynamic>);
  }
}
