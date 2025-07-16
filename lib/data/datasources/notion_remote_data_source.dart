import 'dart:convert';

import 'package:http/http.dart' as http;

class NotionRemoteDataSource {
  static const String _notionApiVersion = '2022-06-28';
  final String apiToken;

  NotionRemoteDataSource({required this.apiToken});

  Future<List<dynamic>> getPagesFromDB(String databaseId) async {
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
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['results'];
    } else {
      throw Exception('Failed to load pages from Notion: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo(String databaseId) async {
    final url = Uri.parse('https://api.notion.com/v1/databases/$databaseId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionApiVersion,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load database info: ${response.body}');
    }
  }

  Future<String> getPageContent(String pageId) async {
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
            contentBuffer.writeln(textItem['plain_text']);
          }
        }
      }
      return contentBuffer.toString();
    } else {
      throw Exception('Failed to load page content: ${response.body}');
    }
  }

  Future<List<dynamic>> searchDatabases({String? query}) async {
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

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['results'];
    } else {
      throw Exception('Failed to search databases: ${response.body}');
    }
  }

  Future<List<dynamic>> getRoadmapTasksFromDB(String databaseId) async {
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

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['results'];
    } else {
      throw Exception(
        'Failed to load roadmap tasks from Notion: ${response.body}',
      );
    }
  }

  Future<List<Map<String, String>>> getQuizDataFromDB(String databaseId) async {
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
      throw Exception('Failed to load quiz data from Notion: ${response.body}');
    }
  }
}
