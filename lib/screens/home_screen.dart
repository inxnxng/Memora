import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/screens/heatmap/heatmap_screen.dart';
import 'package:memora/screens/profile/profile_screen.dart';
import 'package:memora/screens/review/til_review_selection_screen.dart';
import 'package:memora/screens/settings/notion_settings_screen.dart';
import 'package:memora/screens/settings/settings_screen.dart';
import 'package:memora/services/settings_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color _heatmapColor = heatmapColorOptions
      .firstWhere((c) => c.name == kDefaultHeatmapColor)
      .color;

  @override
  void initState() {
    super.initState();
    _loadHeatmapColor();
  }

  Future<void> _loadHeatmapColor() async {
    final settingsService = context.read<SettingsService>();
    final colorName = await settingsService.getHeatmapColorName();
    final selectedColor = heatmapColorOptions
        .firstWhere(
          (c) => c.name == colorName,
          orElse: () => heatmapColorOptions.firstWhere(
            (c) => c.name == kDefaultHeatmapColor,
          ),
        )
        .color;

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then(
                (_) => _loadHeatmapColor(),
              ); // Reload color when returning from settings
            },
          ),
        ],
      ),
      body: Consumer2<NotionProvider, UserProvider>(
        builder: (context, notionProvider, userProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildHeatmapButton(userProvider)),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TilReviewSelectionScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotionSettingsScreen(),
                          ),
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

  Widget _buildHeatmapButton(UserProvider userProvider) {
    final datasets = userProvider.sessionMap.map((key, value) {
      return MapEntry(DateTime.parse(key), value);
    });

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 10 * 7));

    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HeatmapScreen()),
        );
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableHeight = constraints.maxHeight;
                final double calculatedSize = (availableHeight - 40) / 7;
                final double tileSize = calculatedSize > 0
                    ? calculatedSize
                    : 1.0;
                return IgnorePointer(
                  child: HeatMap(
                    datasets: datasets,
                    startDate: startDate,
                    endDate: endDate,
                    size: tileSize,
                    colorMode: ColorMode.opacity,
                    fontSize: 0,
                    showText: false,
                    scrollable: true,
                    colorsets: {1: _heatmapColor},
                    showColorTip: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
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
