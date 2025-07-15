import 'package:flutter/material.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:provider/provider.dart';

class NotionConnectScreen extends StatefulWidget {
  const NotionConnectScreen({super.key});

  @override
  State<NotionConnectScreen> createState() => _NotionConnectScreenState();
}

class _NotionConnectScreenState extends State<NotionConnectScreen> {
  final _tokenController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    _tokenController.text = notionProvider.apiToken ?? '';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchDatabases(NotionProvider provider) {
    provider.searchNotionDatabases(query: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final notionProvider = Provider.of<NotionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notion 연동 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Notion API Token',
                  hintText: 'Enter your Notion API token here',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final token = _tokenController.text.trim();
                  if (token.isNotEmpty) {
                    context.read<NotionProvider>().setApiToken(token);
                    // Hide keyboard
                    FocusScope.of(context).unfocus();
                  }
                },
                child: const Text('API 토큰 저장 및 확인'),
              ),
              const SizedBox(height: 20),
              if (notionProvider.apiToken != null &&
                  notionProvider.apiToken!.isNotEmpty)
                _buildDatabaseSection(notionProvider),
              const SizedBox(height: 32),
              if (notionProvider.isConnected)
                TextButton(
                  onPressed: () {
                    notionProvider.clearNotionInfo();
                    _tokenController.clear();
                  },
                  child: const Text(
                    '연동 해제',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatabaseSection(NotionProvider notionProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '데이터베이스 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (notionProvider.databaseTitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '현재 연결된 DB: ${notionProvider.databaseTitle}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: '데이터베이스 이름 검색',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _searchDatabases(notionProvider),
            ),
          ),
          onSubmitted: (_) => _searchDatabases(notionProvider),
        ),
        const SizedBox(height: 10),
        if (notionProvider.isSearchingDatabases)
          const Center(child: CircularProgressIndicator())
        else if (notionProvider.notionConnectionError != null)
          Text(
            notionProvider.notionConnectionError!,
            style: const TextStyle(color: Colors.red),
          )
        else if (notionProvider.availableDatabases.isNotEmpty)
          _buildDatabaseList(notionProvider)
        else
          const Text('검색 결과가 없습니다.'),
      ],
    );
  }

  Widget _buildDatabaseList(NotionProvider notionProvider) {
    return SizedBox(
      height: 300, // Give it a fixed height or use Expanded in a Column
      child: ListView.builder(
        itemCount: notionProvider.availableDatabases.length,
        itemBuilder: (context, index) {
          final db = notionProvider.availableDatabases[index];
          final title = db['title']?[0]?['plain_text'] ?? '제목 없음';
          final dbId = db['id'];

          return Card(
            child: ListTile(
              title: Text(title),
              onTap: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await notionProvider.connectNotionDatabase(dbId, title);

                if (!mounted) return;
                // Dismiss loading indicator
                Navigator.pop(context);

                // Show snackbar based on result
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      notionProvider.notionConnectionError == null
                          ? '$title 데이터베이스가 연결되었습니다.'
                          : notionProvider.notionConnectionError!,
                    ),
                    backgroundColor:
                        notionProvider.notionConnectionError == null
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
