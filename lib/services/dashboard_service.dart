import '../models/dashboard.dart';
import '../models/software.dart';
import 'api_client.dart';

class DashboardService {
  final ApiClient _api = ApiClient();

  Future<DashboardStats?> getStats() async {
    try {
      final resp = await _api.get('/dashboard');
      return DashboardStats.fromJson(resp);
    } catch (e) {
      return null;
    }
  }

  Future<List<SoftwareModel>> getSoftwareList() async {
    try {
      final resp = await _api.getList('/software');
      return resp.map((e) => SoftwareModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
