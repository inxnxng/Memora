import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class ResponsiveHeatmap extends StatelessWidget {
  final Map<DateTime, int>? datasets;
  final DateTime? startDate;
  final DateTime? endDate;
  final Color heatmapColor;
  /// Border radius of each cell. Use 0 for square cells.
  final double borderRadius;

  const ResponsiveHeatmap({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.endDate,
    required this.heatmapColor,
    this.borderRadius = 0,
  });

  static const double _cellMargin = 4.0;
  static const double _horizontalPadding = 32.0;
  static const double _verticalPadding = 24.0;
  static const int _daysPerRow = 7;

  @override
  Widget build(BuildContext context) {
    if (startDate == null || endDate == null) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final media = MediaQuery.of(context);
    final viewWidth = media.size.width;
    final viewHeight = media.size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : viewWidth;
        // Use a fraction of viewport height so heatmap never overflows the screen
        final double maxHeatmapHeight = viewHeight * 0.4;
        final int totalDays =
            endDate!.difference(startDate!).inDays + 1;
        final int weeks = (totalDays / _daysPerRow).ceil().clamp(1, 52);

        // Tile size from width: 7 days per row
        double tileSizeFromWidth =
            (maxWidth - _horizontalPadding) / _daysPerRow;
        // Tile size from height: fit all rows in allocated height
        double tileSizeFromHeight =
            (maxHeatmapHeight - _verticalPadding) / weeks - _cellMargin;

        double tileSize = (tileSizeFromWidth < tileSizeFromHeight
                ? tileSizeFromWidth
                : tileSizeFromHeight)
            .clamp(10.0, 28.0);

        // 좌측 요일 라벨(Sun, Mon 등) 너비 추정 후 클리핑으로 숨김
        const double weekLabelWidth = 32.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: viewHeight * 0.45,
            maxWidth: maxWidth,
          ),
          child: SizedBox(
            width: maxWidth,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: OverflowBox(
                alignment: Alignment.centerRight,
                maxWidth: maxWidth + weekLabelWidth,
                child: Transform.translate(
                  offset: Offset(-weekLabelWidth, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    reverse: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: HeatMap(
                          datasets: datasets,
                          startDate: startDate!,
                          endDate: endDate!,
                          size: tileSize,
                          colorMode: ColorMode.opacity,
                          showText: false,
                          scrollable: false,
                          colorsets: {1: heatmapColor},
                          showColorTip: false,
                          borderRadius: borderRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
