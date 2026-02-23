import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(title: '설정'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _buildSectionLabel(context, '연동'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSettingsTile(
              context,
              icon: Icons.cloud_queue_rounded,
              title: 'Notion 연동 관리',
              subtitle: 'API 키 및 데이터베이스 설정',
              onTap: () {
                context.push('${AppRoutes.settings}/${AppRoutes.notionSettings}');
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel(context, 'AI'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.psychology_rounded,
                  title: 'AI 모델 선택',
                  subtitle: '퀴즈 생성에 사용할 모델 선택',
                  onTap: () {
                    context.push(
                        '${AppRoutes.settings}/${AppRoutes.aiModelSettings}');
                  },
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _buildSettingsTile(
                  context,
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'OpenAI API 키',
                  subtitle: 'API 키 등록 및 관리',
                  onTap: () {
                    context.push(
                        '${AppRoutes.settings}/${AppRoutes.openaiSettings}');
                  },
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _buildSettingsTile(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: 'Gemini API 키',
                  subtitle: 'API 키 등록 및 관리',
                  onTap: () {
                    context.push(
                        '${AppRoutes.settings}/${AppRoutes.geminiSettings}');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel(context, '표시'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSettingsTile(
              context,
              icon: Icons.color_lens_outlined,
              title: '히트맵 색상',
              subtitle: '학습 기록 히트맵 색상 변경',
              onTap: () {
                context.push(
                  '${AppRoutes.settings}/${AppRoutes.heatmapColorSettings}',
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel(context, '앱 정보'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSettingsTile(
              context,
              icon: Icons.info_outline_rounded,
              title: '앱 소개',
              subtitle: 'Memora 소개 및 기능 안내',
              onTap: () async {
                final uri = Uri.parse(AppStrings.appIntroUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 24,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 24,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
