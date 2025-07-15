import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotionService {
  static const String _notionApiVersion = '2022-06-28';
  static const String _apiTokenKey = 'notion_api_token';
  static const String _apiTokenTimestampKey = 'notion_api_token_timestamp';
  static const String _databaseIdKey = 'notion_database_id';
  static const String _databaseIdTimestampKey = 'notion_database_id_timestamp';
  static const String _databaseTitleKey = 'notion_database_title';
  static const String _databaseTitleTimestampKey =
      'notion_database_title_timestamp';
  static const String _databaseKey = 'notion_database';
  static const String _databaseTimestampKey = 'notion_database_timestamp';

  Future<void> saveApiToken(String apiToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiTokenKey, apiToken);
    await prefs.setString(
      _apiTokenTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> saveDatabaseId(String databaseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databaseIdKey, databaseId);
    await prefs.setString(
      _databaseIdTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> saveDatabaseTitle(String databaseTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databaseTitleKey, databaseTitle);
    await prefs.setString(
      _databaseTitleTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> saveDatabase(String database) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databaseKey, database);
    await prefs.setString(
      _databaseTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> getDatabaseWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final database = prefs.getString(_databaseKey);
    final timestamp = prefs.getString(_databaseTimestampKey);
    return {'value': database, 'timestamp': timestamp};
  }

  Future<Map<String, String?>> getNotionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiToken = prefs.getString(_apiTokenKey);
    String? databaseId = prefs.getString(_databaseIdKey);
    String? databaseTitle = prefs.getString(_databaseTitleKey);

    String? database = prefs.getString(_databaseKey);

    return {
      'apiToken': apiToken,
      'databaseId': databaseId,
      'databaseTitle': databaseTitle,
      'database': database,
    };
  }

  Future<Map<String, String?>> getApiTokenWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString(_apiTokenKey);
    final timestamp = prefs.getString(_apiTokenTimestampKey);
    return {'value': apiToken, 'timestamp': timestamp};
  }

  Future<Map<String, String?>> getDatabaseIdWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseId = prefs.getString(_databaseIdKey);
    final timestamp = prefs.getString(_databaseIdTimestampKey);
    return {'value': databaseId, 'timestamp': timestamp};
  }

  Future<Map<String, String?>> getDatabaseTitleWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseTitle = prefs.getString(_databaseTitleKey);
    final timestamp = prefs.getString(_databaseTitleTimestampKey);
    return {'value': databaseTitle, 'timestamp': timestamp};
  }

  Future<void> clearDatabaseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_databaseIdKey);
    await prefs.remove(_databaseIdTimestampKey);
    await prefs.remove(_databaseTitleKey);
    await prefs.remove(_databaseTitleTimestampKey);
    await prefs.remove(_databaseKey);
    await prefs.remove(_databaseTimestampKey);
  }

  Future<void> clearNotionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiTokenKey);
    await prefs.remove(_apiTokenTimestampKey);
    await prefs.remove(_databaseIdKey);
    await prefs.remove(_databaseIdTimestampKey);
    await prefs.remove(_databaseTitleKey);
    await prefs.remove(_databaseTitleTimestampKey);
    await prefs.remove(_databaseKey);
    await prefs.remove(_databaseTimestampKey);
  }

  Future<List<dynamic>> getPagesFromDB(
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
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['results'];
    } else {
      throw Exception('Failed to load pages from Notion: ${response.body}');
    }
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

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load database info: ${response.body}');
    }
  }

  Future<String> getPageContent(String pageId, String apiToken) async {
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

  Future<List<dynamic>> searchDatabases(
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

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['results'];
    } else {
      throw Exception('Failed to search databases: ${response.body}');
    }
  }

  Future<List<dynamic>> getRoadmapTasksFromDB(
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

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['results'];
    } else {
      throw Exception(
        'Failed to load roadmap tasks from Notion: ${response.body}',
      );
    }
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
      throw Exception('Failed to load quiz data from Notion: ${response.body}');
    }
  }
}
