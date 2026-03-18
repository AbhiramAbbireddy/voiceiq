import '../../../core/network/api_client.dart';
import 'auth_session.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String targetRole,
  }) {
    return _apiClient.post<AuthSession>(
      '/api/v1/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'targetRole': targetRole,
      },
      parser: AuthSession.fromJson,
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _apiClient.post<AuthSession>(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      parser: AuthSession.fromJson,
    );
  }
}
