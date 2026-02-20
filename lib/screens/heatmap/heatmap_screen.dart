import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:memora/widgets/responsive_heatmap.dart';
import 'package:provider/provider.dart';

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
            _buildHeatmapCard(taskProvider),
            const SizedBox(height: 24),
            Text(
              AppStrings.detailedLearningRecord,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildSessionList(taskProvider.heatmapData),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapCard(TaskProvider taskProvider) {
    final heatmapDatasets = taskProvider.heatmapData.map(
      (date, records) => MapEntry(date, records.length),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ResponsiveHeatmap(
          datasets: heatmapDatasets,
          startDate: taskProvider.heatmapStartDate,
          endDate: taskProvider.heatmapEndDate,
          heatmapColor: taskProvider.heatmapColor,
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

              if (dbName.isEmpty && title.isEmpty) {
                return const SizedBox.shrink();
              }

              return ListTile(
                title: Text(title.isEmpty ? "" : title),
                subtitle: Text(
                  dbName.isEmpty ? "" : AppStrings.databasePrefix(dbName),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
