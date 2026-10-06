import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';

/// Custom Exception for Plant Recognition API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isConnectionError;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.isConnectionError = false,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Central API Client wrapper using Dio.
class ApiClient {
  final Dio _dio;
  String _baseUrl;

  ApiClient({String? baseUrl, Dio? dio})
      : _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConfig.defaultBaseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                sendTimeout: ApiConfig.sendTimeout,
                headers: {
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          logPrint: (obj) => debugPrint('[ApiClient] $obj'),
        ),
      );
    }
  }

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  Dio get rawDio => _dio;

  /// Check whether the backend is reachable
  Future<bool> isBackendReachable() async {
    try {
      final response = await _dio.get(
        ApiConfig.modelsEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Perform GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Lỗi không xác định: $e', originalError: e);
    }
  }

  /// Perform POST request with Multipart/Form-data
  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Lỗi tải ảnh lên: $e', originalError: e);
    }
  }

  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Kết nối tới máy chủ AI quá thời gian quy định (Timeout).',
          isConnectionError: true,
          originalError: e,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Không thể kết nối tới máy chủ backend tại $_baseUrl. Vui lòng đảm bảo ASP.NET Core API đang chạy.',
          isConnectionError: true,
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String serverMsg = 'Máy chủ phản hồi mã lỗi $status';
        if (data is Map && data.containsKey('message')) {
          serverMsg = data['message'].toString();
        }
        return ApiException(
          message: serverMsg,
          statusCode: status,
          originalError: e,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Yêu cầu nhận dạng đã bị hủy.',
          originalError: e,
        );
      default:
        return ApiException(
          message: 'Lỗi kết nối mạng: ${e.message ?? "Không xác định"}',
          isConnectionError: true,
          originalError: e,
        );
    }
  }
}
