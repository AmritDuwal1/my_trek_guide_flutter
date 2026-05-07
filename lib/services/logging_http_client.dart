import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Wraps [http.Client] and prints URL, request body, and response body for each call.
///
/// Use for debugging only — logs may include personal data and tokens if present in bodies.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  static const int _maxBodyChars = 12000;

  String _describeRequestBody(http.BaseRequest request) {
    if (request is http.Request) {
      final body = request.body;
      return body.isEmpty ? '(empty)' : body;
    }
    if (request is http.MultipartRequest) {
      final fields = request.fields;
      return '(multipart, fields: $fields, files: ${request.files.length})';
    }
    return '(${request.runtimeType})';
  }

  String _truncateBody(String text) {
    if (text.length <= _maxBodyChars) return text;
    return '${text.substring(0, _maxBodyChars)}… (${text.length - _maxBodyChars} more chars)';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    debugPrint('[API] → ${request.method} $url');
    debugPrint('[API] request body: ${_describeRequestBody(request)}');

    final streamed = await _inner.send(request);
    final bytes = await streamed.stream.toBytes();
    final decoded = utf8.decode(bytes, allowMalformed: true);
    debugPrint('[API] ← ${streamed.statusCode} $url');
    debugPrint('[API] response body: ${_truncateBody(decoded)}');

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      streamed.statusCode,
      contentLength: bytes.length,
      request: streamed.request,
      headers: streamed.headers,
      reasonPhrase: streamed.reasonPhrase,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
