import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/services/openai_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenAISettingsScreen extends StatefulWidget {
  const OpenAISettingsScreen({super.key});

  @override
  State<OpenAISettingsScreen> createState() => _OpenAISettingsScreenState();
}

class _OpenAISettingsScreenState extends State<OpenAISettingsScreen> {
  late final OpenAIService _openAIService;
  final TextEditingController _openAIApiKeyController = TextEditingController();
  Map<String, String?> _openAIApiKey = {'value': null, 'timestamp': null};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() {
      _isLoading = true;
    });
    _openAIApiKey = await _openAIService.getApiKeyWithTimestamp();
    _openAIApiKeyController.text = ''; // Clear controller
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
    final token = _openAIApiKeyController.text.trim();

    if (token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OpenAI API Key를 입력해주세요.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      await _openAIService.saveApiKeyWithTimestamp(
        _openAIApiKeyController.text,
      );
      await _loadKeys(); // Reload to update timestamp
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OpenAI API Key 저장 완료!')));
      _openAIApiKeyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OpenAI API Key 저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OpenAI API 키 설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('OpenAI API Key 설정'),
                  const SizedBox(height: 8),
                  const Text(
                    'Memora의 퀴즈 생성 기능에 사용됩니다. API 키는 로컬 디바이스에만 안전하게 저장됩니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionCard(),
                  const SizedBox(height: 16),
                  _buildKeyInput(
                    controller: _openAIApiKeyController,
                    label: 'OpenAI API Key',
                    currentValue: _openAIApiKey['value'],
                    timestamp: _openAIApiKey['timestamp'],
                    onSave: _saveOpenAIApiKey,
                  ),
                ],
              ),
            ),
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
          'API 키 발급 방법',
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
                  text: "OpenAI의 ",
                  linkText: "API Keys 페이지로 이동",
                  url: "https://platform.openai.com/api-keys",
                  linkColor: linkColor,
                ),
                _buildStep(
                  icon: Icons.add_circle_outline,
                  text: "'+ Create new secret key'를 클릭하여 키를 생성합니다.",
                ),
                _buildStep(
                  icon: Icons.copy,
                  text: "생성된 API Key를 복사하여 아래에 붙여넣으세요.",
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

  Widget _buildKeyInput({
    required TextEditingController controller,
    required String label,
    required String? timestamp,
    required VoidCallback onSave,
    String? currentValue,
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
            hintText: 'sk-... 형태의 API 키를 입력하세요',
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
    _openAIApiKeyController.dispose();
    super.dispose();
  }
}
