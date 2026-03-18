import '../../../core/network/api_client.dart';
import 'subscription_summary.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<SubscriptionSummary> getCurrentSubscription() {
    return _apiClient.get<SubscriptionSummary>(
      '/api/v1/subscription/me',
      SubscriptionSummary.fromJson,
    );
  }
}
