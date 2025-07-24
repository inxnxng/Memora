import 'package:flutter/material.dart';
import 'package:memora/screens/settings/notion_settings_screen.dart';
import 'package:memora/screens/settings/openai_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.cloud_queue,
            title: 'Notion 연동 관리',
            subtitle: 'API 키 및 데이터베이스를 설정합니다.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotionSettingsScreen()),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.lightbulb_outline,
            title: 'OpenAI API 키 설정',
            subtitle: '퀴즈 생성에 사용될 API 키를 관리합니다.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OpenAISettingsScreen()),
              );
            },
          ),
          // Add other settings later if needed
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 28, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}