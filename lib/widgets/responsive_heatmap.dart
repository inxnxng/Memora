import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class ResponsiveHeatmap extends StatelessWidget {
  final Map<DateTime, int>? datasets;
  final DateTime? startDate;
  final DateTime? endDate;
  final Color heatmapColor;

  const ResponsiveHeatmap({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.endDate,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    if (startDate == null || endDate == null) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        // Calculate appropriate tile size
        // We want about 15-20 weeks to show at once if possible on mobile,
        // but more on wider screens.
        double tileSize = (screenWidth - 32) / 12; // 18 weeks view as default

        // Minimum tile size for readability
        if (tileSize < 18) tileSize = 12;
        // Maximum tile size to keep it looking like a heatmap
        if (tileSize > 30) tileSize = 25;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          // Reverse scroll direction so the most recent dates (end) are visible first
          reverse: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: HeatMap(
              datasets: datasets,
              startDate: startDate!,
              endDate: endDate!,
              size: tileSize,
              colorMode: ColorMode.opacity,
              showText: false,
              scrollable:
                  false, // We use our own SingleChildScrollView for better control
              colorsets: {1: heatmapColor},
              showColorTip: false,
            ),
          ),
        );
      },
    );
  }
}
