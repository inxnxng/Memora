import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/constants/storage_keys.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  Color _heatmapColor = heatmapColorOptions
      .firstWhere((c) => c.name == StorageKeys.defaultHeatmapColor)
      .color;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadHeatmapColor();
        // Fetch heatmap data when the screen is initialized
        Provider.of<TaskProvider>(context, listen: false).fetchHeatmapData();
      }
    });
  }

  Future<void> _loadHeatmapColor() async {
    final colorString = await _localStorageService.getValue(
      StorageKeys.heatmapColorKey,
    );

    Color selectedColor;

    if (colorString != null) {
      try {
        // Try parsing as a hex string first (new format)
        selectedColor = Color(int.parse(colorString, radix: 16));
      } catch (e) {
        // If parsing fails, assume it's a color name (old format)
        final colorOption = heatmapColorOptions.firstWhere(
          (c) => c.name == colorString,
          orElse: () => heatmapColorOptions.firstWhere(
            (c) => c.name == StorageKeys.defaultHeatmapColor,
          ),
        );
        selectedColor = colorOption.color;
      }
    } else {
      // If no color is saved, use the default
      final defaultColorOption = heatmapColorOptions.firstWhere(
        (c) => c.name == StorageKeys.defaultHeatmapColor,
      );
      selectedColor = defaultColorOption.color;
    }

    if (mounted) {
      setState(() {
        _heatmapColor = selectedColor;
      });
    }
  }

  String _getProfileImage(ProficiencyLevel? level) {
    String imageLevel = level?.name.toLowerCase() ?? 'default';
    switch (imageLevel) {
      case 'beginner':
      case 'intermediate':
      case 'advanced':
      case 'master':
        return 'assets/images/proficiency_levels/$imageLevel.png';
      default:
        return 'assets/images/proficiency_levels/default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return GestureDetector(
              onTap: () {
                context.push(AppRoutes.profile);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage(
                    _getProfileImage(userProvider.userLevel),
                  ),
                ),
              ),
            );
          },
        ),
        title: const Text('🧠 Memora'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context
                  .push(AppRoutes.settings)
                  .then(
                    (_) => _loadHeatmapColor(),
                  ); // Reload color when returning from settings
            },
          ),
        ],
      ),
      body: Consumer3<NotionProvider, UserProvider, TaskProvider>(
        builder: (context, notionProvider, userProvider, taskProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildHeatmapButton(taskProvider)),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildMenuButton(
                    context,
                    icon: Icons.article,
                    label: 'TIL 복습',
                    subLabel:
                        notionProvider.notionConnectionError ??
                        (notionProvider.isConnected
                            ? (notionProvider.databaseTitle ?? 'Notion DB 연결됨')
                            : 'Notion 연결 필요'),
                    onPressed: () {
                      if (notionProvider.isConnected) {
                        context.push(AppRoutes.review);
                      } else {
                        context.push(
                          '${AppRoutes.settings}/${AppRoutes.notionSettings}',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeatmapButton(TaskProvider taskProvider) {
    final detailedDatasets = taskProvider.heatmapData;
    final heatmapDatasets = detailedDatasets.map(
      (date, records) => MapEntry(date, records.length),
    );

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 10 * 7));

    return ElevatedButton(
      onPressed: () {
        context.push(AppRoutes.heatmap);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '학습 기록',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 10),
          IgnorePointer(
            child: HeatMap(
              datasets: heatmapDatasets,
              startDate: startDate,
              endDate: endDate,
              size: 15,
              colorMode: ColorMode.opacity,
              fontSize: 0,
              showText: false,
              scrollable: true,
              colorsets: {1: _heatmapColor},
              showColorTip: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    String? subLabel,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 28)),
          if (subLabel != null) ...[
            const SizedBox(height: 5),
            Text(
              subLabel,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
