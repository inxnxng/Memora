import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  Color _heatmapColor = heatmapColorOptions
      .firstWhere((c) => c.name == kDefaultHeatmapColor)
      .color;

  @override
  void initState() {
    super.initState();
    _loadHeatmapColor();
  }

  Future<void> _loadHeatmapColor() async {
    final colorName =
        await _localStorageService.getValue(kHeatmapColorKey) ??
        kDefaultHeatmapColor;
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final datasets = userProvider.sessionMap.map((key, value) {
      return MapEntry(DateTime.parse(key), value);
    });

    final DateTime endDate = DateTime.now();
    DateTime startDate;

    if (datasets.isEmpty) {
      // Default to last 90 days if no data
      startDate = endDate.subtract(const Duration(days: 90));
    } else {
      final DateTime earliestDate = datasets.keys.reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
      final int daysDifference = endDate.difference(earliestDate).inDays;

      if (daysDifference < 90) {
        // If the earliest record is within 90 days, show the last 90 days.
        startDate = endDate.subtract(const Duration(days: 90));
      } else {
        // If older than 90 days, calculate weeks needed and set start date.
        final int totalDays = (daysDifference / 7).ceil() * 7;
        startDate = endDate.subtract(Duration(days: totalDays - 1));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('학습 현황')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakCard(context, userProvider.streakCount),
            const SizedBox(height: 24),
            Text('학습 기록', style: Theme.of(context).textTheme.headlineSmall),
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
                  startDate: startDate,
                  endDate: endDate,
                  colorMode: ColorMode.opacity,
                  showText: false,
                  scrollable: true,
                  colorsets: {1: _heatmapColor},
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('학습 상세 기록', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildSessionList(datasets),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(Map<DateTime, int> datasets) {
    if (datasets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('학습 기록이 없습니다.'),
        ),
      );
    }

    final sortedEntries = datasets.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final date = entry.key;
        final count = entry.value;
        final formattedDate = "${date.year}년 ${date.month}월 ${date.day}일";

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(formattedDate),
            trailing: Text(
              '총 $count회 학습',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
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
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              '현재 $streakCount일 연속 학습 중!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
