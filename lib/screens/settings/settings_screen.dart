import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/utils/platform_utils.dart';
import 'package:memora/widgets/common_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '설정'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.cloud_queue,
            title: 'Notion 연동 관리',
            subtitle: 'API 키 및 데이터베이스를 설정합니다.',
            onTap: () {
              context.push('${AppRoutes.settings}/${AppRoutes.notionSettings}');
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.lightbulb_outline,
            title: 'OpenAI API 키 설정',
            subtitle: '퀴즈 생성에 사용될 API 키를 관리합니다.',
            onTap: () {
              context.push('${AppRoutes.settings}/${AppRoutes.openaiSettings}');
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.auto_awesome,
            title: 'Gemini API 키 설정',
            subtitle: '퀴즈 생성에 사용될 API 키를 관리합니다.',
            onTap: () {
              context.push('${AppRoutes.settings}/${AppRoutes.geminiSettings}');
            },
          ),
          if (!PlatformUtils.isApple)
            _buildSettingsItem(
              context,
              icon: Icons.notifications_outlined,
              title: '알림 설정',
              subtitle: '매일 복습 시간을 설정합니다.',
              onTap: () {
                context.push(
                  '${AppRoutes.settings}/${AppRoutes.notificationSettings}',
                );
              },
            ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.color_lens_outlined,
            title: '히트맵 색상 변경',
            subtitle: '학습 기록 히트맵의 색상을 변경합니다.',
            onTap: () {
              context.push(
                '${AppRoutes.settings}/${AppRoutes.heatmapColorSettings}',
              );
            },
          ),
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
