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
