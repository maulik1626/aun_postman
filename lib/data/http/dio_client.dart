import 'dart:io';

import 'package:aun_postman/core/constants/app_constants.dart';
import 'package:aun_postman/core/utils/json_comment_stripper.dart';
import 'package:aun_postman/core/errors/error_handler.dart';
import 'package:aun_postman/data/http/interceptors/auth_interceptor.dart';
import 'package:aun_postman/data/http/interceptors/digest_auth_interceptor.dart';
import 'package:aun_postman/data/http/interceptors/timing_interceptor.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/http_response.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:aun_postman/domain/models/response_cookie.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';

class DioClient {
  static Future<HttpResponse> execute(
    HttpRequest request, {
    CancelToken? cancelToken,
    int timeoutSeconds = AppConstants.defaultTimeoutSeconds,
    bool followRedirects = true,
    bool verifySsl = true,
    String httpProxy = '',
    List<RequestHeader> defaultHeaders = const [],
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: Duration(seconds: timeoutSeconds),
        sendTimeout: Duration(seconds: timeoutSeconds),
        followRedirects: followRedirects,
        validateStatus: (_) => true, // accept all status codes
        responseType: ResponseType.bytes,
      ),
    );

    if (!kIsWeb) {
      final adapter = dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        final proxy = httpProxy.trim();
        adapter.createHttpClient = () {
          final client = HttpClient();
          if (!verifySsl) {
            client.badCertificateCallback = (cert, host, port) => true;
          }
          if (proxy.isNotEmpty) {
            client.findProxy = (_) {
              if (proxy.toUpperCase() == 'DIRECT') return 'DIRECT';
              if (proxy.contains('://')) {
                final u = Uri.parse(proxy);
                final h = u.host;
                final p = u.hasPort ? u.port : 8080;
                return 'PROXY $h:$p';
              }
              return 'PROXY $proxy';
            };
          }
          return client;
        };
      }
    }

    dio.interceptors.addAll([
      TimingInterceptor(),
      AuthInterceptor(request.auth),
      if (request.auth case final DigestAuth d)
        DigestAuthInterceptor(dio, d),
    ]);

    // Build URL with enabled params
    var url = request.url;
    final enabledParams = request.params.where((p) => p.isEnabled).toList();
    if (enabledParams.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final queryParams = Map<String, String>.fromEntries(
          enabledParams.map((p) => MapEntry(p.key, p.value)),
        );
        url = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...queryParams,
        }).toString();
      }
    }

    // Build headers: app defaults first, then request (request overwrites same key).
    final headers = <String, String>{};
    for (final d in defaultHeaders.where((h) => h.isEnabled)) {
      final k = d.key.trim();
      if (k.isEmpty) continue;
      headers[k] = d.value;
    }
    for (final h in request.headers.where((x) => x.isEnabled)) {
      headers[h.key] = h.value;
    }

    // Build body
    dynamic data;
    if (request.method.value != 'GET' && request.method.value != 'HEAD') {
      data = await _buildBody(request.body, headers);
    }

    try {
      final response = await dio.request<List<int>>(
        url,
        data: data,
        options: Options(
          method: request.method.value,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      final bodyBytes = response.data ?? <int>[];
      final bodyString = String.fromCharCodes(bodyBytes);
      final durationMs =
          response.requestOptions.extra['duration_ms'] as int? ?? 0;

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final cookies = _parseCookies(
        response.headers.map['set-cookie'] ?? [],
      );

      return HttpResponse(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        headers: responseHeaders,
        body: bodyString,
        durationMs: durationMs,
        sizeBytes: bodyBytes.length,
        cookies: cookies,
        receivedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  static Future<dynamic> _buildBody(
    RequestBody body,
    Map<String, String> headers,
  ) async {
    // Auto-inject Content-Type when the user hasn't set one
    final hasContentType =
        headers.keys.any((k) => k.toLowerCase() == 'content-type');
    if (!hasContentType) {
      switch (body) {
        case RawJsonBody():
          headers['Content-Type'] = 'application/json; charset=utf-8';
        case RawXmlBody():
          headers['Content-Type'] = 'application/xml; charset=utf-8';
        case RawHtmlBody():
          headers['Content-Type'] = 'text/html; charset=utf-8';
        case RawTextBody():
          headers['Content-Type'] = 'text/plain; charset=utf-8';
        case UrlEncodedBody():
          headers['Content-Type'] = 'application/x-www-form-urlencoded';
        default:
          break;
      }
    }

    return switch (body) {
      NoBody() => null,
      RawJsonBody(:final content) => stripJsonLineComments(content),
      RawXmlBody(:final content) => content,
      RawTextBody(:final content) => content,
      RawHtmlBody(:final content) => content,
      UrlEncodedBody(:final fields) => fields
          .where((f) => f.isEnabled)
          .map((f) => '${Uri.encodeQueryComponent(f.key)}=${Uri.encodeQueryComponent(f.value)}')
          .join('&'),
      FormDataBody(:final fields) => _buildFormData(fields),
      BinaryBody(:final filePath, :final mimeType) => await _buildBinary(
          filePath,
          mimeType,
          headers,
        ),
    };
  }

  static FormData _buildFormData(List<FormDataField> fields) {
    final formData = FormData();
    for (final field in fields.where((f) => f.isEnabled)) {
      if (field.isFile && field.filePath != null) {
        final mime = lookupMimeType(field.filePath!) ?? 'application/octet-stream';
        formData.files.add(
          MapEntry(
            field.key,
            MultipartFile.fromFileSync(
              field.filePath!,
              contentType: DioMediaType.parse(mime),
            ),
          ),
        );
      } else {
        formData.fields.add(MapEntry(field.key, field.value));
      }
    }
    return formData;
  }

  static Future<MultipartFile> _buildBinary(
    String filePath,
    String? mimeType,
    Map<String, String> headers,
  ) async {
    final mime = mimeType ??
        lookupMimeType(filePath) ??
        'application/octet-stream';
    headers['Content-Type'] = mime;
    return MultipartFile.fromFileSync(
      filePath,
      contentType: DioMediaType.parse(mime),
    );
  }

  static List<ResponseCookie> _parseCookies(List<String> setCookieHeaders) {
    return setCookieHeaders.map((header) {
      final parts = header.split(';');
      final nameValue = parts.first.trim().split('=');
      final name = nameValue.first.trim();
      final value = nameValue.length > 1 ? nameValue.sublist(1).join('=') : '';

      String? domain;
      String? path;
      DateTime? expires;
      bool httpOnly = false;
      bool secure = false;

      for (final part in parts.skip(1)) {
        final trimmed = part.trim().toLowerCase();
        if (trimmed.startsWith('domain=')) {
          domain = part.trim().substring(7);
        } else if (trimmed.startsWith('path=')) {
          path = part.trim().substring(5);
        } else if (trimmed.startsWith('expires=')) {
          try {
            expires = HttpDate.parse(part.trim().substring(8));
          } catch (_) {}
        } else if (trimmed == 'httponly') {
          httpOnly = true;
        } else if (trimmed == 'secure') {
          secure = true;
        }
      }

      return ResponseCookie(
        name: name,
        value: value,
        domain: domain,
        path: path,
        expires: expires,
        httpOnly: httpOnly,
        secure: secure,
      );
    }).toList();
  }
}
