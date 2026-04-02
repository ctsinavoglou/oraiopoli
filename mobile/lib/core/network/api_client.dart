import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());
final tokenStorageProvider = Provider((ref) => TokenStorage(ref.read(secureStorageProvider)));

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'accessToken');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshToken = await storage.read(key: 'refreshToken');
        if (refreshToken != null) {
          try {
            final res = await Dio().post(
              '${ApiConstants.baseUrl}${ApiConstants.authRefresh}',
              data: {'refreshToken': refreshToken},
            );
            final newToken = res.data['data']['accessToken'];
            await storage.write(key: 'accessToken', value: newToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {
            await storage.deleteAll();
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});

