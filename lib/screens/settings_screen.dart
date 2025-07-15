import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/notion_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotionService _notionService = NotionService();
  final LocalStorageService _localStorageService = LocalStorageService();

  Map<String, String?> _openAIApiKey = {'value': null, 'timestamp': null};
  Map<String, String?> _notionApiToken = {'value': null, 'timestamp': null};

  final TextEditingController _openAIApiKeyController = TextEditingController();
  final TextEditingController _notionApiTokenController =
      TextEditingController();
  final TextEditingController _notionDatabaseSearchController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() {
      _isLoading = true;
    });
    _openAIApiKey = await _localStorageService.getApiKeyWithTimestamp();
    _notionApiToken = await _notionService.getApiTokenWithTimestamp();

    // Do not pre-fill controllers with actual values for security and UX.
    // The masked value is shown separately.
    _openAIApiKeyController.text = '';
    _notionApiTokenController.text = '';
    _notionDatabaseSearchController.text = ''; // Clear search controller

    setState(() {
      _isLoading = false;
    });
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '미입력';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yy.MM.dd HH:mm').format(dateTime);
  }

  Future<void> _saveOpenAIApiKey() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _localStorageService.saveApiKeyWithTimestamp(
        _openAIApiKeyController.text,
      );
      await _loadKeys(); // Reload to update timestamp
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OpenAI API Key 저장 완료!')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OpenAI API Key 저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotionApiToken() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<NotionProvider>(
        context,
        listen: false,
      ).setApiToken(_notionApiTokenController.text);
      await _loadKeys(); // Reload to update timestamp
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notion API Token 저장 완료!'),
          ), // Removed one of the snackbars
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notion API Token 저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('OpenAI 설정'),
                  _buildKeyInput(
                    controller: _openAIApiKeyController,
                    label: 'OpenAI API Key',
                    timestamp: _openAIApiKey['timestamp'],
                    onSave: _saveOpenAIApiKey,
                    currentValue: _openAIApiKey['value'],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Notion 설정'),
                  _buildKeyInput(
                    controller: _notionApiTokenController,
                    label: 'Notion API Token',
                    timestamp: _notionApiToken['timestamp'],
                    onSave:
                        _saveNotionApiToken, // This will save both Notion fields
                    currentValue: _notionApiToken['value'],
                  ),

                  const SizedBox(height: 30),
                  _buildSectionTitle('Notion 데이터베이스 검색'),
                  TextField(
                    controller: _notionDatabaseSearchController,
                    decoration: InputDecoration(
                      hintText: '데이터베이스 이름으로 검색',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          Provider.of<NotionProvider>(
                            context,
                            listen: false,
                          ).searchNotionDatabases(
                            query: _notionDatabaseSearchController.text,
                          );
                        },
                      ),
                    ),
                    onSubmitted: (query) {
                      Provider.of<NotionProvider>(
                        context,
                        listen: false,
                      ).searchNotionDatabases(query: query);
                    },
                  ),
                  Consumer<NotionProvider>(
                    builder: (context, notionProvider, child) {
                      if (notionProvider.isSearchingDatabases) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (notionProvider.notionConnectionError != null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            notionProvider.notionConnectionError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (notionProvider.availableDatabases.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('검색 결과가 없습니다.'),
                        );
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notionProvider.availableDatabases.length,
                          itemBuilder: (context, index) {
                            final db = notionProvider.availableDatabases[index];
                            final dbTitle =
                                db['title']?[0]?['plain_text'] ?? '제목 없음';
                            final dbId = db['id'];
                            return ListTile(
                              title: Text(dbTitle),
                              subtitle: Text(dbId),
                              trailing: notionProvider.databaseId == dbId
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                              onTap: () async {
                                await notionProvider.connectNotionDatabase(
                                  dbId,
                                  dbTitle,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Notion 데이터베이스 연결 완료: $dbTitle',
                                    ),
                                  ),
                                );
                                _loadKeys(); // Reload to update UI
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  Widget _buildKeyInput({
    required TextEditingController controller,
    required String label,
    required String? timestamp,
    required VoidCallback onSave,
    String? currentValue, // New parameter to pass the actual stored value
  }) {
    String maskedValue = '';
    if (currentValue != null && currentValue.isNotEmpty) {
      maskedValue = currentValue.length > 5
          ? '${currentValue.substring(0, 5)}*****'
          : '*****';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (maskedValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '현재 값: $maskedValue',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        TextField(
          controller: controller,
          obscureText: true,
          onSubmitted: (_) => onSave(),
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            border: const OutlineInputBorder(),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh), // Refresh icon for apply
                    onPressed: onSave,
                    tooltip: '적용',
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '마지막 업데이트: ${_formatTimestamp(timestamp)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  void dispose() {
    _openAIApiKeyController.dispose();
    _notionApiTokenController.dispose();
    _notionDatabaseSearchController.dispose();
    super.dispose();
  }
}
