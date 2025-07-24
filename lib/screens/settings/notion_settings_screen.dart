import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  late final NotionProvider _notionProvider;
  final TextEditingController _notionApiTokenController =
      TextEditingController();
  final TextEditingController _notionDatabaseSearchController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notionProvider = Provider.of<NotionProvider>(context, listen: false);
    // Load initial state without causing rebuilds before build method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    // You might want to show existing token's masked value or status
    // For now, we just ensure the provider has the latest state.
    setState(() {});
  }

  Future<void> _saveNotionApiToken() async {
    if (_notionApiTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notion API 토큰을 입력해주세요.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _notionProvider.setApiToken(_notionApiTokenController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notion API Token 저장 완료!')),
        );
        _notionApiTokenController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notion API Token 저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using Consumer at a higher level to react to provider changes
    return Consumer<NotionProvider>(
      builder: (context, notionProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Notion 연동 관리')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('API 키 설정'),
                _buildInstructionCard(),
                const SizedBox(height: 16),
                _buildKeyInput(
                  controller: _notionApiTokenController,
                  label: 'Notion API Token',
                  onSave: _saveNotionApiToken,
                  currentValue: notionProvider.apiToken,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('데이터베이스 연결'),
                const Text(
                  'API 키를 저장하고 데이터베이스에 연결 권한을 부여한 후, 아래에서 데이터베이스를 검색하고 선택하세요.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notionDatabaseSearchController,
                  decoration: InputDecoration(
                    hintText: '데이터베이스 이름으로 검색',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        notionProvider.searchNotionDatabases(
                          query: _notionDatabaseSearchController.text,
                        );
                      },
                    ),
                  ),
                  onSubmitted: (query) {
                    notionProvider.searchNotionDatabases(query: query);
                  },
                ),
                const SizedBox(height: 10),
                _buildDatabaseList(notionProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notion API 키 발급 및 연동 방법',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildStep(1, "Notion의 ", "내 연동 페이지로 이동", "https://www.notion.so/my-integrations"),
            _buildStep(2, "'+ 새 연동 만들기' 버튼을 클릭하여 'Memora' 등의 이름으로 연동을 생성합니다."),
            _buildStep(3, "생성된 '내부 연동 토큰'을 복사하여 아래에 붙여넣고 저장합니다."),
            const Divider(height: 24),
            _buildStep(4, "Memora와 연동할 Notion 데이터베이스 페이지 우측 상단 '...' 메뉴에서 '+ 연결 추가'를 선택합니다."),
            _buildStep(5, "검색창에서 방금 만든 연동('Memora')을 찾아 선택하여 데이터베이스 접근 권한을 부여합니다."),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text, [String? linkText, String? url]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(text: text),
                  if (linkText != null && url != null)
                    TextSpan(
                      text: linkText,
                      style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseList(NotionProvider notionProvider) {
    if (notionProvider.isSearchingDatabases) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notionProvider.notionConnectionError != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          notionProvider.notionConnectionError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (notionProvider.availableDatabases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('검색 결과가 없거나, API 토큰이 유효하지 않습니다.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notionProvider.availableDatabases.length,
      itemBuilder: (context, index) {
        final db = notionProvider.availableDatabases[index];
        final dbTitle = db['title']?[0]?['plain_text'] ?? '제목 없음';
        final dbId = db['id'];
        return ListTile(
          title: Text(dbTitle),
          subtitle: Text(dbId),
          trailing: notionProvider.databaseId == dbId
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          onTap: () async {
            await notionProvider.connectNotionDatabase(dbId, dbTitle);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notion 데이터베이스 연결 완료: $dbTitle')),
            );
          },
        );
      },
    );
  }

  Widget _buildKeyInput({
    required TextEditingController controller,
    required String label,
    required VoidCallback onSave,
    String? currentValue,
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
                    icon: const Icon(Icons.save),
                    onPressed: onSave,
                    tooltip: '저장',
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  @override
  void dispose() {
    _notionApiTokenController.dispose();
    _notionDatabaseSearchController.dispose();
    super.dispose();
  }
}


