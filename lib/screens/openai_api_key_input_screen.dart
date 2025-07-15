import 'package:flutter/material.dart';
import 'package:memora/services/openai_service.dart';

class OpenAIApiKeyInputScreen extends StatefulWidget {
  const OpenAIApiKeyInputScreen({super.key});

  @override
  State<OpenAIApiKeyInputScreen> createState() =>
      _OpenAIApiKeyInputScreenState();
}

class _OpenAIApiKeyInputScreenState extends State<OpenAIApiKeyInputScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingApiKey();
  }

  Future<void> _loadExistingApiKey() async {
    // This will load from SharedPreferences or .env if available
    final apiKey = await _openAIService.getApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
  }

  Future<void> _saveApiKey() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _openAIService.saveApiKey(_apiKeyController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key saved successfully!')),
        );
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving API Key: ${e.toString()}')),
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
      appBar: AppBar(title: const Text('OpenAI API Key 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'OpenAI API Key를 입력해주세요. 이 키는 기기에 안전하게 저장됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // Hide the key
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('저장'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
