import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotionApiException implements Exception {
  final String message;
  final int? statusCode;
  NotionApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'NotionApiException: $message (Status code: $statusCode)';
  }
}

class NotionRemoteDataSource {
  static const String _notionApiVersion = '2022-06-28';

  /// 웹 빌드일 때만 사용. 같은 오리진의 Notion 프록시 URL (CORS 회피).
  static String? get _proxyBaseUrl => kIsWeb ? Uri.base.origin : null;

  NotionRemoteDataSource();

  /// 웹에서 Notion API를 같은 오리진 프록시로 호출. 프록시가 응답을 그대로 반환함.
  Future<http.Response> _callViaProxy(
    String apiToken,
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final base = _proxyBaseUrl;
    if (base == null) throw StateError('_callViaProxy is for web only');
    final url = Uri.parse('$base/api/notion-proxy');
    // Just return the response directly. No need to create a new one.
    return await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'path': path, 'method': method, 'body': ?body}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    // Decode with utf8 to prevent character corruption.
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw NotionApiException(
        'Notion resource not found: $body',
        statusCode: response.statusCode,
      );
    } else {
      throw NotionApiException(
        'Failed to load data from Notion: $body',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getPagesFromDB(
    String apiToken,
    String databaseId, [
    String? startCursor,
  ]) async {
    final Map<String, dynamic> body = {};
    if (startCursor != null) {
      body['start_cursor'] = startCursor;
    }
    if (_proxyBaseUrl != null) {
      final response = await _callViaProxy(
        apiToken,
        'databases/$databaseId/query',
        method: 'POST',
        body: body,
      );
      return _handleResponse(response);
    }
    final url = Uri.parse(
      'https://api.notion.com/v1/databases/$databaseId/query',
    );
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDatabaseInfo(
    String apiToken,
    String databaseId,
  ) async {
    if (_proxyBaseUrl != null) {
      final response = await _callViaProxy(
        apiToken,
        'databases/$databaseId',
        method: 'GET',
      );
      return _handleResponse(response);
    }
    final url = Uri.parse('https://api.notion.com/v1/databases/$databaseId');
    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
          },
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<String> getPageContent(String apiToken, String pageId) async {
    final http.Response response;
    if (_proxyBaseUrl != null) {
      response = await _callViaProxy(
        apiToken,
        'blocks/$pageId/children',
        method: 'GET',
      );
    } else {
      final url = Uri.parse(
        'https://api.notion.com/v1/blocks/$pageId/children',
      );
      response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Notion-Version': _notionApiVersion,
            },
          )
          .timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body) as Map<String, dynamic>;
      final blocks = data['results'] as List;
      final contentBuffer = StringBuffer();

      for (var block in blocks) {
        final type = block['type'];
        if (block.containsKey(type) && block[type].containsKey('rich_text')) {
          final richText = block[type]['rich_text'] as List;
          for (var textItem in richText) {
            contentBuffer.writeln(
              (textItem as Map<String, dynamic>)['plain_text'],
            );
          }
        }
      }
      return contentBuffer.toString();
    } else {
      final body = utf8.decode(response.bodyBytes);
      throw NotionApiException(
        'Failed to load page content: $body',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> searchDatabases(
    String apiToken, {
    String? query,
  }) async {
    final body = {
      'query': query,
      'filter': {'property': 'object', 'value': 'database'},
    };
    if (_proxyBaseUrl != null) {
      final response = await _callViaProxy(
        apiToken,
        'search',
        method: 'POST',
        body: body,
      );
      return _handleResponse(response);
    }
    final url = Uri.parse('https://api.notion.com/v1/search');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> searchPages(
    String apiToken, {
    String? query,
  }) async {
    final body = {
      'query': query,
      'filter': {'property': 'object', 'value': 'page'},
    };
    if (_proxyBaseUrl != null) {
      final response = await _callViaProxy(
        apiToken,
        'search',
        method: 'POST',
        body: body,
      );
      return _handleResponse(response);
    }
    final url = Uri.parse('https://api.notion.com/v1/search');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getRoadmapTasksFromDB(
    String apiToken,
    String databaseId,
  ) async {
    final body = {
      'sorts': [
        {'timestamp': 'created_time', 'direction': 'ascending'},
      ],
    };
    if (_proxyBaseUrl != null) {
      final response = await _callViaProxy(
        apiToken,
        'databases/$databaseId/query',
        method: 'POST',
        body: body,
      );
      return _handleResponse(response);
    }
    final url = Uri.parse(
      'https://api.notion.com/v1/databases/$databaseId/query',
    );
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<List<Map<String, String>>> getQuizDataFromDB(
    String apiToken,
    String databaseId,
  ) async {
    final body = {
      'filter': {
        'and': [
          {
            'property': 'Question',
            'text': {'is_not_empty': true},
          },
          {
            'property': 'Answer',
            'text': {'is_not_empty': true},
          },
        ],
      },
    };
    final http.Response response;
    if (_proxyBaseUrl != null) {
      response = await _callViaProxy(
        apiToken,
        'databases/$databaseId/query',
        method: 'POST',
        body: body,
      );
    } else {
      final url = Uri.parse(
        'https://api.notion.com/v1/databases/$databaseId/query',
      );
      response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Notion-Version': _notionApiVersion,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final results =
          (json.decode(body) as Map<String, dynamic>)['results'] as List;
      return results.map((page) {
        final properties = page['properties'];
        final question =
            properties['Question']['title'][0]['plain_text'] as String;
        final answer =
            properties['Answer']['rich_text'][0]['plain_text'] as String;
        return {'question': question, 'answer': answer};
      }).toList();
    } else {
      final body = utf8.decode(response.bodyBytes);
      throw NotionApiException(
        'Failed to load quiz data from Notion: $body',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> fetchPageBlocks(
    String apiToken,
    String pageId,
  ) async {
    if (_proxyBaseUrl != null) {
      final response = await _callViaProxy(
        apiToken,
        'blocks/$pageId/children?page_size=100',
        method: 'GET',
      );
      return _handleResponse(response);
    }
    final url = Uri.parse(
      'https://api.notion.com/v1/blocks/$pageId/children?page_size=100',
    );
    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Notion-Version': _notionApiVersion,
          },
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<bool> validateApiKey(String apiToken) async {
    debugPrint("Validating Notion API key...");
    try {
      final http.Response response;
      if (_proxyBaseUrl != null) {
        response = await _callViaProxy(apiToken, 'users/me', method: 'GET');
      } else {
        final url = Uri.parse('https://api.notion.com/v1/users/me');
        response = await http
            .get(
              url,
              headers: {
                'Authorization': 'Bearer $apiToken',
                'Notion-Version': _notionApiVersion,
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
