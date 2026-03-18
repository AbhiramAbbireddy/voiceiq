import '../../../core/network/api_client.dart';
import 'feedback_report.dart';

class FeedbackRepository {
  FeedbackRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<FeedbackReport> getReport(String sessionId) {
    return _apiClient.get<FeedbackReport>(
      '/api/v1/feedback/reports/$sessionId',
      FeedbackReport.fromJson,
    );
  }
}
