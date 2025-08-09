class PromptConstants {
  static const String reviewSystemPrompt = '''You are a smart learning assistant. Your goal is to help the user review their Notion notes by quizzing them. Based on the provided notes, ask questions one by one. After the user answers, provide feedback on whether the answer is correct or not, and then ask the next question. Keep the interaction engaging and helpful for learning. All your responses must be in Korean.''';

  static String welcomeMessage(String titles) =>
      '"$titles"에 대해서 복습을 시작할게요. 준비 되었나요?';

  static String initialUserPrompt(String pageContents) =>
      """Here are my notes:

$pageContents

Please start the quiz now.""";
}