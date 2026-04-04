import 'package:aun_postman/domain/enums/http_method.dart';
import 'package:aun_postman/domain/models/auth_config.dart';
import 'package:aun_postman/domain/models/http_request.dart';
import 'package:aun_postman/domain/models/key_value_pair.dart';
import 'package:aun_postman/domain/models/request_body.dart';
import 'package:uuid/uuid.dart';

class CurlParser {
  static const _uuid = Uuid();

  static HttpRequest? parse(String curlCommand) {
    try {
      final tokens = _tokenize(curlCommand.trim());
      if (tokens.isEmpty) return null;

      var method = HttpMethod.get;
      String url = '';
      final headers = <RequestHeader>[];
      String bodyContent = '';
      String? username;
      String? password;

      int i = 0;
      while (i < tokens.length) {
        final token = tokens[i];
        switch (token) {
          case 'curl':
            i++;
          case '-X':
          case '--request':
            i++;
            if (i < tokens.length) {
              method = HttpMethod.fromString(tokens[i]);
              i++;
            }
          case '-H':
          case '--header':
            i++;
            if (i < tokens.length) {
              final parts = tokens[i].split(':');
              if (parts.length >= 2) {
                headers.add(RequestHeader(
                  key: parts[0].trim(),
                  value: parts.sublist(1).join(':').trim(),
                ));
              }
              i++;
            }
          case '-d':
          case '--data':
          case '--data-raw':
          case '--data-ascii':
            i++;
            if (i < tokens.length) {
              bodyContent = tokens[i];
              if (method == HttpMethod.get) method = HttpMethod.post;
              i++;
            }
          case '-u':
          case '--user':
            i++;
            if (i < tokens.length) {
              final parts = tokens[i].split(':');
              username = parts[0];
              password = parts.length > 1 ? parts[1] : '';
              i++;
            }
          default:
            if (!token.startsWith('-') && url.isEmpty) {
              url = token;
            }
            i++;
        }
      }

      if (url.isEmpty) return null;

      final uri = Uri.tryParse(url);
      final params = uri?.queryParameters.entries
              .map((e) => RequestParam(key: e.key, value: e.value))
              .toList() ??
          [];
      final cleanUrl =
          uri != null ? url.split('?').first : url;

      RequestBody body = const NoBody();
      if (bodyContent.isNotEmpty) {
        final contentType = headers
            .where((h) => h.key.toLowerCase() == 'content-type')
            .firstOrNull;
        if (contentType != null &&
            contentType.value.contains('application/json')) {
          body = RawJsonBody(content: bodyContent);
        } else {
          body = RawTextBody(content: bodyContent);
        }
      }

      AuthConfig auth = const NoAuth();
      if (username != null) {
        auth = BasicAuth(username: username, password: password ?? '');
      }

      final now = DateTime.now();
      return HttpRequest(
        uid: _uuid.v4(),
        name: 'Imported Request',
        method: method,
        url: cleanUrl,
        params: params,
        headers: headers,
        body: body,
        auth: auth,
        createdAt: now,
        updatedAt: now,
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inSingle = false;
    var inDouble = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
      } else if ((ch == ' ' || ch == '\n' || ch == '\t' || ch == '\\') &&
          !inSingle &&
          !inDouble) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }
}
