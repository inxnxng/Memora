import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/notion_route_extra.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:memora/widgets/responsive_heatmap.dart';
import 'package:provider/provider.dart';

/// 최근 히트맵 표시 기간(일). 12주 = 84일.
const int _recentHeatmapDays = 12 * 7;

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchHeatmapData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final endDate = DateTime.now();
    final startDate = endDate.subtract(
      const Duration(days: _recentHeatmapDays),
    );
    final recentData = _filterRecentHeatmapData(
      taskProvider.heatmapData,
      startDate,
      endDate,
    );

    return Scaffold(
      appBar: const CommonAppBar(title: AppStrings.heatmapTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.learningRecord,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildHeatmapCard(
              taskProvider: taskProvider,
              recentData: recentData,
              startDate: startDate,
              endDate: endDate,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.detailedLearningRecord,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildSessionList(recentData),
          ],
        ),
      ),
    );
  }

  static Map<DateTime, List<Map<String, dynamic>>> _filterRecentHeatmapData(
    Map<DateTime, List<Map<String, dynamic>>> fullData,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    return Map.fromEntries(
      fullData.entries.where((e) {
        final d = e.key;
        final norm = DateTime(d.year, d.month, d.day);
        return !norm.isBefore(normalizedStart) && !norm.isAfter(normalizedEnd);
      }),
    );
  }

  Widget _buildHeatmapCard({
    required TaskProvider taskProvider,
    required Map<DateTime, List<Map<String, dynamic>>> recentData,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final heatmapDatasets = recentData.map(
      (date, records) => MapEntry(date, records.length),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ResponsiveHeatmap(
          datasets: heatmapDatasets,
          startDate: startDate,
          endDate: endDate,
          heatmapColor: taskProvider.heatmapColor,
          borderRadius: 0,
        ),
      ),
    );
  }

  Widget _buildSessionList(Map<DateTime, List<Map<String, dynamic>>> datasets) {
    if (datasets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(AppStrings.noLearningRecord),
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
        final records = entry.value;
        final count = records.length;
        final formattedDate = AppStrings.formattedDate(
          date.year,
          date.month,
          date.day,
        );

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ExpansionTile(
            leading: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(formattedDate),
            trailing: Text(
              AppStrings.totalLearningCount(count),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            children: records.map((record) {
              final dbName = record['databaseName'] as String? ?? '';
              final title = record['title'] as String? ?? '';
              final pageId = record['pageId'] as String?;
              final url = record['url'] as String?;

              if (dbName.isEmpty && title.isEmpty) {
                return const SizedBox.shrink();
              }

              final canOpenPage = pageId != null && pageId.isNotEmpty;

              return ListTile(
                title: Text(title.isEmpty ? "" : title),
                subtitle: Text(
                  dbName.isEmpty ? "" : AppStrings.databasePrefix(dbName),
                ),
                trailing: canOpenPage
                    ? Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: canOpenPage
                    ? () {
                        final extra = NotionRouteExtra(
                          databaseName: dbName.isNotEmpty
                              ? dbName
                              : AppStrings.unknownDb,
                          pageId: pageId,
                          pageTitle: title,
                          url: url,
                          alreadyCompleted: true,
                        );
                        context.push(
                          '${AppRoutes.review}/${AppRoutes.notionPage}',
                          extra: extra,
                        );
                      }
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
