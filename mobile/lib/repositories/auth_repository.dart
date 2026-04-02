import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider), ref.read(tokenStorageProvider));
});

class AuthRepository {
  final Dio _dio;
  final TokenStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<AuthResult> register({
    required String fullName, required String email, required String phone,
    required String address, required String password,
  }) async {
    final res = await _dio.post(ApiConstants.authRegister, data: {
      'fullName': fullName, 'email': email, 'phone': phone,
      'address': address, 'password': password,
    });
    final auth = AuthResult.fromJson(res.data['data']);
    await _saveTokens(auth);
    return auth;
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final res = await _dio.post(ApiConstants.authLogin, data: {'email': email, 'password': password});
    final auth = AuthResult.fromJson(res.data['data']);
    await _saveTokens(auth);
    return auth;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'accessToken');
    return token != null;
  }

  Future<User?> getSavedUser() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return null;
    try {
      final res = await _dio.get(ApiConstants.customerProfile);
      return User.fromJson(res.data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTokens(AuthResult auth) async {
    await _storage.write(key: 'accessToken', value: auth.accessToken);
    await _storage.write(key: 'refreshToken', value: auth.refreshToken);
  }
}

