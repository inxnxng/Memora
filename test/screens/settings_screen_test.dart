import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/screens/settings/notion_settings_screen.dart';
import 'package:memora/screens/settings/openai_settings_screen.dart';
import 'package:memora/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  // Set up a mock for SharedPreferences before running tests
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders settings items and navigates to Notion settings',
        (WidgetTester tester) async {
      // Build the SettingsScreen
      await tester.pumpWidget(createTestableWidget(child: const SettingsScreen()));

      // Verify that the main settings items are rendered
      expect(find.text('Notion 연동 관리'), findsOneWidget);
      expect(find.text('API 키 및 데이터베이스를 설정합니다.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_queue), findsOneWidget);

      // Tap on the 'Notion 연동 관리' list tile
      await tester.tap(find.text('Notion 연동 관리'));
      await tester.pumpAndSettle(); // Wait for navigation animation

      // Verify that we have navigated to the NotionSettingsScreen
      expect(find.byType(NotionSettingsScreen), findsOneWidget);
      expect(find.text('Notion 연동 관리'), findsOneWidget); // AppBar title
    });

    testWidgets('renders settings items and navigates to OpenAI settings',
        (WidgetTester tester) async {
      // Build the SettingsScreen
      await tester.pumpWidget(createTestableWidget(child: const SettingsScreen()));

      // Verify that the main settings items are rendered
      expect(find.text('OpenAI API 키 설정'), findsOneWidget);
      expect(find.text('퀴즈 생성에 사용될 API 키를 관리합니다.'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      // Tap on the 'OpenAI API 키 설정' list tile
      await tester.tap(find.text('OpenAI API 키 설정'));
      await tester.pumpAndSettle(); // Wait for navigation animation

      // Verify that we have navigated to the OpenAISettingsScreen
      expect(find.byType(OpenAISettingsScreen), findsOneWidget);
      expect(find.text('OpenAI API 키 설정'), findsOneWidget); // AppBar title
    });
  });
}
