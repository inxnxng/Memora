import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final TextEditingController _notionApiTokenController =
      TextEditingController();
  final TextEditingController _notionDatabaseSearchController =
      TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotionProvider>(context, listen: false).initialize();
    });
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '미입력';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yy.MM.dd HH:mm').format(dateTime);
  }

  Future<void> _saveNotionApiToken() async {
    final token = _notionApiTokenController.text.trim();
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notion API 토큰을 입력해주세요.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await notionProvider.setApiToken(token);

      if (notionProvider.apiToken != null) {
        // Sync to Firestore if the token is valid and saved
        await userProvider.syncAllApiKeysToFirestore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notion Key 저장 및 인증 완료!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notion Key가 유효하지 않습니다.')),
          );
        }
      }

      _notionApiTokenController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notion Key 저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotionProvider>(
      builder: (context, notionProvider, child) {
        return Scaffold(
          appBar: const CommonAppBar(title: 'Notion 연동 관리'),
          body: notionProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                        currentValue: notionProvider.apiToken,
                        timestamp: notionProvider.apiTokenTimestamp,
                        isValid: notionProvider.apiToken != null,
                        onSave: _saveNotionApiToken,
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
                      if (notionProvider.databaseTitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            '현재 연결된 DB: ${notionProvider.databaseTitle}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _buildDatabaseList(notionProvider),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInstructionCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? theme.colorScheme.surfaceContainerHighest.withAlpha(
            (255 * 0.3).round(),
          )
        : theme.colorScheme.surfaceContainerHighest;
    final linkColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          'API 키 발급 및 연동 방법',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('자세한 안내 보기'),
        leading: Icon(
          Icons.integration_instructions_outlined,
          color: theme.colorScheme.primary,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildStep(
                  icon: Icons.link,
                  text: "Notion의 ",
                  linkText: "내 연동 페이지로 이동",
                  url: "https://www.notion.so/profile/integrations/internal",
                  linkColor: linkColor,
                ),
                _buildStep(
                  icon: Icons.add_circle_outline,
                  text: "'+ 새 연동 만들기'를 클릭하여 연동을 생성합니다.",
                ),
                _buildStep(
                  icon: Icons.copy,
                  text: "생성된 '내부 연동 토큰'을 복사하여 아래에 붙여넣으세요.",
                ),
                const Divider(height: 24),
                _buildStep(
                  icon: Icons.add_link,
                  text: "연동할 Notion 페이지 우측 상단 '...' 메뉴에서 '+ 연결 추가'를 선택하세요.",
                ),
                _buildStep(
                  icon: Icons.search,
                  text: "검색창에서 방금 만든 연동을 찾아 선택하여 권한을 부여합니다.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String text,
    String? linkText,
    String? url,
    Color? linkColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(text: text),
                  if (linkText != null && url != null)
                    TextSpan(
                      text: linkText,
                      style: TextStyle(
                        color: linkColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(Uri.parse(url)),
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
    if (notionProvider.notionConnectionError != null &&
        notionProvider.availableDatabases.isEmpty) {
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
        final dbTitle = db.title;
        final dbId = db.id;
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
    String? timestamp,
    bool? isValid,
  }) {
    String maskedValue = '';
    if (currentValue != null && currentValue.isNotEmpty) {
      maskedValue = currentValue.length > 8
          ? '${currentValue.substring(0, 8)}*****'
          : '*****';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (maskedValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  '현재 키: $maskedValue',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                if (isValid != null)
                  Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid ? Colors.green : Colors.red,
                    size: 16,
                  ),
              ],
            ),
          ),
        TextField(
          controller: controller,
          obscureText: true,
          onSubmitted: (_) => onSave(),
          decoration: InputDecoration(
            hintText: 'ntn... 형태의 API 키를 입력하세요',
            border: const OutlineInputBorder(),
            suffixIcon: _isSaving
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
        const SizedBox(height: 8),
        Text(
          '마지막 업데이트: ${_formatTimestamp(timestamp)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
