import 'dart:convert';

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

  // Constructor is now empty
  NotionRemoteDataSource();

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 404) {
      throw NotionApiException(
        'Notion resource not found: ${response.body}',
        statusCode: response.statusCode,
      );
    } else {
      throw NotionApiException(
        'Failed to load data from Notion: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getPagesFromDB(
    String apiToken,
    String databaseId, [
    String? startCursor,
  ]) async {
    final url = Uri.parse(
      'https://api.notion.com/v1/databases/$databaseId/query',
    );

    final Map<String, dynamic> body = {};
    if (startCursor != null) {
      body['start_cursor'] = startCursor;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDatabaseInfo(
    String apiToken,
    String databaseId,
  ) async {
    final url = Uri.parse('https://api.notion.com/v1/databases/$databaseId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
      },
    );
    return _handleResponse(response);
  }

  Future<String> getPageContent(String apiToken, String pageId) async {
    final url = Uri.parse('https://api.notion.com/v1/blocks/$pageId/children');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
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
      throw NotionApiException(
        'Failed to load page content: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> searchDatabases(
    String apiToken, {
    String? query,
  }) async {
    final url = Uri.parse('https://api.notion.com/v1/search');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'filter': {'property': 'object', 'value': 'database'},
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> searchPages(
    String apiToken, {
    String? query,
  }) async {
    final url = Uri.parse('https://api.notion.com/v1/search');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'filter': {'property': 'object', 'value': 'page'},
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getRoadmapTasksFromDB(
    String apiToken,
    String databaseId,
  ) async {
    final url = Uri.parse(
      'https://api.notion.com/v1/databases/$databaseId/query',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sorts': [
          {'timestamp': 'created_time', 'direction': 'ascending'},
        ],
      }),
    );
    return _handleResponse(response);
  }

  Future<List<Map<String, String>>> getQuizDataFromDB(
    String apiToken,
    String databaseId,
  ) async {
    final url = Uri.parse(
      'https://api.notion.com/v1/databases/$databaseId/query',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
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
      }),
    );

    if (response.statusCode == 200) {
      final results =
          json.decode(utf8.decode(response.bodyBytes))['results'] as List;
      return results.map((page) {
        final properties = page['properties'];
        final question =
            properties['Question']['title'][0]['plain_text'] as String;
        final answer =
            properties['Answer']['rich_text'][0]['plain_text'] as String;
        return {'question': question, 'answer': answer};
      }).toList();
    } else {
      throw NotionApiException(
        'Failed to load quiz data from Notion: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> fetchPageBlocks(
    String apiToken,
    String pageId,
  ) async {
    final url = Uri.parse(
      'https://api.notion.com/v1/blocks/$pageId/children?page_size=100',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
      },
    );
    return _handleResponse(response);
  }

  Future<bool> validateApiKey(String apiToken) async {
    final url = Uri.parse('https://api.notion.com/v1/users/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
      },
    );
    return response.statusCode == 200;
  }
}
