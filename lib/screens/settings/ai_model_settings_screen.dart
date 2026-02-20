import 'package:flutter/material.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

enum AiProvider { gemini, openai }

extension AiProviderExtension on AiProvider {
  String get name {
    switch (this) {
      case AiProvider.gemini:
        return 'Gemini';
      case AiProvider.openai:
        return 'OpenAI';
    }
  }
}

class AiModelSettingsScreen extends StatelessWidget {
  const AiModelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'AI 모델 선택'),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                '퀴즈 생성에 사용할 AI 모델을 선택하세요. 선택한 모델의 API 키가 설정되어 있어야 합니다.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<AiProvider>(
                value: userProvider.preferredAi,
                onChanged: (AiProvider? newValue) {
                  if (newValue != null) {
                    userProvider.setPreferredAi(newValue);
                  }
                },
                items: AiProvider.values.map((AiProvider provider) {
                  return DropdownMenuItem<AiProvider>(
                    value: provider,
                    child: Text(provider.name),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: '선호 AI 모델',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
