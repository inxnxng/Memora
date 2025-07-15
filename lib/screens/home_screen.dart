import 'package:flutter/material.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/screens/notion_connect_screen.dart';
import 'package:memora/screens/roadmap_screen.dart';
import 'package:memora/screens/settings_screen.dart';
import 'package:memora/screens/til_review_selection_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Memora'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotionProvider>(
        builder: (context, notionProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMenuButton(
                    context,
                    icon: Icons.psychology,
                    label: '기억력 향상',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoadmapScreen(),
                        ),
                      );
                    },
                  ),
                ),
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
                            builder: (context) => const NotionConnectScreen(),
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
