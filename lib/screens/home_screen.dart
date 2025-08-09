import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Data is now loaded in providers' initialization
        // but we can refresh it here if needed, e.g., when returning to the screen.
        context.read<TaskProvider>().loadHeatmapColor();
        context.read<TaskProvider>().fetchHeatmapData();
      }
    });
  }

  String _getProfileImage(ProficiencyLevel? level) {
    String imageLevel = level?.name.toLowerCase() ?? 'default';
    // A simple mapping to asset paths.
    // Consider moving this to the ProficiencyLevel model or a dedicated helper.
    const basePath = 'assets/images/proficiency_levels/';
    const validLevels = {'beginner', 'intermediate', 'advanced', 'master'};
    return validLevels.contains(imageLevel)
        ? '$basePath$imageLevel.png'
        : '${basePath}default.png';
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
        title: const Text(AppStrings.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context
                  .push(AppRoutes.settings)
                  .then((_) => context.read<TaskProvider>().loadHeatmapColor());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildHeatmapButton(context)),
            const SizedBox(height: 20),
            Expanded(child: _buildTilReviewButton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapButton(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final heatmapDatasets = taskProvider.heatmapData.map(
      (date, records) => MapEntry(date, records.length),
    );
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 10 * 7));

    return ElevatedButton(
      onPressed: () => context.push(AppRoutes.heatmap),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            AppStrings.learningRecord,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 10),
          if (taskProvider.isLoading)
            const CircularProgressIndicator()
          else
            IgnorePointer(
              child: HeatMap(
                datasets: heatmapDatasets,
                startDate: startDate,
                endDate: endDate,
                size: 20,
                fontSize: 0,
                colorMode: ColorMode.opacity,
                showText: false,
                scrollable: true,
                colorsets: {1: taskProvider.heatmapColor},
                showColorTip: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTilReviewButton(BuildContext context) {
    final notionProvider = context.watch<NotionProvider>();
    return ElevatedButton(
      onPressed: () {
        if (notionProvider.isConnected) {
          context.push(AppRoutes.review);
        } else {
          context.push('${AppRoutes.settings}/${AppRoutes.notionSettings}');
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article, size: 48),
          const SizedBox(height: 10),
          const Text(AppStrings.tilReview, style: TextStyle(fontSize: 28)),
          const SizedBox(height: 5),
          Text(
            notionProvider.notionConnectionError ??
                (notionProvider.isConnected
                    ? (notionProvider.databaseTitle ??
                          AppStrings.notionConnected)
                    : AppStrings.notionConnectionNeeded),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
