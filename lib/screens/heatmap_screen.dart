import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Convert sessionMap keys from String to DateTime for the heatmap widget
    final datasets = userProvider.sessionMap.map((key, value) {
      return MapEntry(DateTime.parse(key), value);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 현황'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakCard(context, userProvider.streakCount),
            const SizedBox(height: 24),
            Text(
              '학습 기록',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: HeatMap(
                  datasets: datasets,
                  colorMode: ColorMode.opacity,
                  showText: false,
                  scrollable: true,
                  colorsets: {
                    1: Theme.of(context).primaryColor,
                  },
                  onClick: (date) {
                    final count = datasets[date] ?? 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${date.month}월 ${date.day}일: 학습 $count회')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streakCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department,
                color: Colors.orange, size: 32),
            const SizedBox(width: 16),
            Text(
              '현재 $streakCount일 연속 학습 중!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
