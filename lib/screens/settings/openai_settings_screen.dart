import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenaiSettingsScreen extends StatefulWidget {
  const OpenaiSettingsScreen({super.key});

  @override
  State<OpenaiSettingsScreen> createState() => _OpenaiSettingsScreenState();
}

class _OpenaiSettingsScreenState extends State<OpenaiSettingsScreen> {
  late final OpenAIService _openaiService;
  final TextEditingController _openaiApiKeyController = TextEditingController();
  Map<String, String?> _openaiApiKey = {'value': null, 'timestamp': null};
  bool _isLoading = false;
  bool _isSaving = false;
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    _openaiService = Provider.of<OpenAIService>(context, listen: false);
    _loadKeys(isInitialLoad: true);
  }

  Future<void> _loadKeys({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      setState(() => _isLoading = true);
    }
    _openaiApiKey = await _openaiService.getApiKeyWithTimestamp();
    if (_openaiApiKey['value'] != null && _openaiApiKey['value']!.isNotEmpty) {
      _isValid = await _openaiService.checkApiKeyAvailability();
    } else {
      _isValid = null;
    }
    _openaiApiKeyController.text = ''; // 컨트롤러 지우기
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '미입력';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yy.MM.dd HH:mm').format(dateTime);
  }

  Future<void> _saveOpenAiApiKey() async {
    final token = _openaiApiKeyController.text.trim();

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI API 키를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isValid = await _openaiService.validateAndSaveApiKey(token);
      await _loadKeys(isInitialLoad: false);

      if (!mounted) return;
      if (isValid) {
        await Provider.of<UserProvider>(context, listen: false)
            .syncAllApiKeysToFirestore();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OpenAI API 키 저장 및 인증이 완료되었습니다.')),
        );
        _openaiApiKeyController.clear();
      } else {
        _showInvalidKeyDialog(token: token);
      }
    } catch (e) {
      if (mounted) {
        _showInvalidKeyDialog(message: '연결에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showInvalidKeyDialog({String? message, String? token}) {
    final offerSaveAnyway = (message == null && token != null && token.isNotEmpty);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 검사 실패'),
        content: Text(
          message ??
              '입력한 API 키가 유효하지 않습니다.\nOpenAI 콘솔에서 키를 확인한 뒤 다시 입력해 주세요.\n\n그래도 저장하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          if (offerSaveAnyway)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isSaving = true);
                try {
                  await _openaiService.saveApiKeyWithoutValidation(token);
                  await Provider.of<UserProvider>(context, listen: false)
                      .syncAllApiKeysToFirestore();
                  if (!mounted) return;
                  await _loadKeys(isInitialLoad: false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('OpenAI API 키가 저장되었습니다. (검증되지 않음)')),
                  );
                  _openaiApiKeyController.clear();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장 실패: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
              child: const Text('그래도 저장'),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'OpenAI API 키 설정'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionCard(),
                  const SizedBox(height: 16),
                  _buildKeyInput(
                    controller: _openaiApiKeyController,
                    label: 'OpenAI API 키',
                    currentValue: _openaiApiKey["value"],
                    timestamp: _openaiApiKey['timestamp'],
                    isValid: _isValid,
                    onSave: _saveOpenAiApiKey,
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
        leading: Icon(Icons.vpn_key_outlined, color: theme.colorScheme.primary),
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
                  linkText: "API 키 페이지로 이동",
                  url: "https://platform.openai.com/api-keys",
                  linkColor: linkColor,
                ),
                _buildStep(
                  icon: Icons.add_circle_outline,
                  text: "에서 ‘새 시크릿 키 만들기’를 클릭해 새 키를 생성하세요.",
                ),
                _buildStep(
                  icon: Icons.copy,
                  text: "생성된 API 키를 복사해 아래 입력란에 붙여넣으세요. (한 번만 표시되니 안전한 곳에 보관하세요.)",
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
            hintText: 'sk-... 형태의 API 키를 입력하세요',
            border: const OutlineInputBorder(),
            suffixIcon: (_isLoading || _isSaving)
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _isSaving ? null : onSave,
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

  @override
  void dispose() {
    _openaiApiKeyController.dispose();
    super.dispose();
  }
}
