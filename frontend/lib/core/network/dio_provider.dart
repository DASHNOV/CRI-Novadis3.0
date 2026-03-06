import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/config/api_config.dart';
import 'package:novadis_cri/core/network/isolate_transformer.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  // Utiliser le transformer par défaut mais avec notre fonction de décodage en Isolate (Natif uniquement)
  if (!kIsWeb) {
    dio.transformer = BackgroundTransformer()
      ..jsonDecodeCallback = jsonDecodeAndCompute;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Handle 401 Unauthorized (Refresh Token)
        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.getRefreshToken();

          if (refreshToken != null) {
            try {
              // Create a new Dio instance to avoid interceptor recursion/conflicts
              // or just use the base options without the interceptor that adds the token
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: ApiConfig.baseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'ngrok-skip-browser-warning': 'true',
                  },
                ),
              );

              // Use the Isolate transformer here as well for consistency (Natif uniquement)
              if (!kIsWeb) {
                refreshDio.transformer = BackgroundTransformer()
                  ..jsonDecodeCallback = jsonDecodeAndCompute;
              }

              final response = await refreshDio.post(
                '/auth/refresh',
                data: {
                  'refreshToken': refreshToken,
                  'deviceInfo': 'Mobile App (Auto-Refresh)',
                },
              );

              if (response.statusCode == 200) {
                // Parse new tokens
                final data =
                    response.data['data']; // Generic ApiResponse structure
                final newAccessToken = data['accessToken'];
                final newRefreshToken = data['refreshToken'];

                if (newAccessToken != null && newRefreshToken != null) {
                  // Save new tokens
                  await storage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Update header for the original request
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';

                  // Retry the original request
                  final clonedRequest = await dio.fetch(options);
                  return handler.resolve(clonedRequest);
                }
              }
            } catch (refreshError) {
              // Refresh failed (token expired or revoked)
              await storage.clearTokens();
              // TODO: Navigate to Login (Need a way to signal this to UI, e.g. stream)
              // For now, just let the error propagate
            }
          } else {
            // No refresh token available, clear any stale data
            await storage.clearTokens();
          }
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
