import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/domain/usecases/openai_usecases.dart';
import 'package:provider/provider.dart';

class OpenAISettingsScreen extends StatefulWidget {
  const OpenAISettingsScreen({super.key});

  @override
  State<OpenAISettingsScreen> createState() => _OpenAISettingsScreenState();
}

class _OpenAISettingsScreenState extends State<OpenAISettingsScreen> {
  late final OpenAIUsecases _openAIUsecases;
  final TextEditingController _openAIApiKeyController = TextEditingController();
  Map<String, String?> _openAIApiKey = {'value': null, 'timestamp': null};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _openAIUsecases = Provider.of<OpenAIUsecases>(context, listen: false);
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() {
      _isLoading = true;
    });
    _openAIApiKey = await _openAIUsecases.getApiKeyWithTimestamp();
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
    if (_openAIApiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI API Key를 입력해주세요.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _openAIUsecases.saveApiKeyWithTimestamp(
        _openAIApiKeyController.text,
      );
      await _loadKeys(); // Reload to update timestamp
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI API Key 저장 완료!')),
      );
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
                  const Text(
                    'OpenAI API Key',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Memora의 퀴즈 생성 기능에 사용됩니다. API 키는 로컬 디바이스에만 안전하게 저장됩니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildKeyInput(
                    controller: _openAIApiKeyController,
                    label: 'OpenAI API Key',
                    timestamp: _openAIApiKey['timestamp'],
                    onSave: _saveOpenAIApiKey,
                    currentValue: _openAIApiKey['value'],
                  ),
                ],
              ),
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

  @override
  void dispose() {
    _openAIApiKeyController.dispose();
    super.dispose();
  }
}
