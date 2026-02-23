import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _getProfileImage(ProficiencyLevel? level) {
    String imageLevel =
        level?.name.toLowerCase() ??
        ProficiencyLevel.beginner.name.toLowerCase();
    const basePath = 'assets/images/proficiency_levels/';
    return '$basePath$imageLevel.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final photoUrl = userProvider.user?.photoURL;
            ImageProvider<Object> backgroundImage;
            if (photoUrl != null && photoUrl.isNotEmpty) {
              backgroundImage = NetworkImage(photoUrl);
            } else {
              backgroundImage = AssetImage(
                _getProfileImage(userProvider.userLevel),
              );
            }
            return GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(backgroundImage: backgroundImage),
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Mem"),
            Column(
              children: [
                const SizedBox(height: 4),
                SvgPicture.asset(
                  'assets/images/icon.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
            Text("ra"),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push(AppRoutes.ranking),
            tooltip: '랭킹',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox.expand(child: _buildHeatmapButton(context)),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: SizedBox.expand(child: _buildTilReviewButton(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapButton(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.heatmap),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_view_month_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.learningRecord,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '탭하여 최근 학습 현황 보기',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTilReviewButton(BuildContext context) {
    final theme = Theme.of(context);
    final notionProvider = context.watch<NotionProvider>();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (notionProvider.isConnected) {
            context.push(AppRoutes.review);
          } else {
            context.push('${AppRoutes.settings}/${AppRoutes.notionSettings}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.tilReview,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notionProvider.notionConnectionError ??
                    (notionProvider.isConnected
                        ? (notionProvider.databaseTitle ??
                              AppStrings.notionConnected)
                        : AppStrings.notionConnectionNeeded),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
