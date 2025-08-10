import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class ResponsiveHeatmap extends StatelessWidget {
  final Map<DateTime, int>? datasets;
  final DateTime startDate;
  final DateTime endDate;
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
    final numberOfDays = endDate.difference(startDate).inDays;
    final numberOfWeeks = (numberOfDays / 7).ceil() + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isInfinite ||
            constraints.maxHeight.isInfinite) {
          return const Center(
            child: Text("Heatmap cannot be rendered in an unbounded space."),
          );
        }

        final double cellWidth = (constraints.maxWidth / numberOfWeeks) - 8;
        final double cellHeight = (constraints.maxHeight / 7) - 2;

        final double cellSize = [
          cellWidth,
          cellHeight,
        ].reduce((a, b) => a < b ? a : b);

        return HeatMap(
          datasets: datasets,
          startDate: startDate,
          endDate: endDate,
          size: cellSize > 0 ? cellSize : 0,
          fontSize: 0,
          colorMode: ColorMode.opacity,
          showText: false,
          scrollable: true,
          colorsets: {1: heatmapColor},
          showColorTip: false,
        );
      },
    );
  }
}
