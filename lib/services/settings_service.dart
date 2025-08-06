import 'package:flutter/material.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/constants/storage_keys.dart';
import 'package:memora/services/local_storage_service.dart';

class SettingsService {
  final LocalStorageService _localStorageService;

  SettingsService(this._localStorageService);

  Future<Color> getHeatmapColor() async {
    final colorString = await _localStorageService.getValue(
      StorageKeys.heatmapColorKey,
    );

    if (colorString != null) {
      try {
        // New format: hex string
        return Color(int.parse(colorString, radix: 16));
      } catch (e) {
        // Old format: color name
        final colorOption = heatmapColorOptions.firstWhere(
          (c) => c.name == colorString,
          orElse: () => heatmapColorOptions.firstWhere(
            (c) => c.name == StorageKeys.defaultHeatmapColor,
          ),
        );
        return colorOption.color;
      }
    } else {
      // Default color
      final defaultColorOption = heatmapColorOptions.firstWhere(
        (c) => c.name == StorageKeys.defaultHeatmapColor,
      );
      return defaultColorOption.color;
    }
  }

  Future<void> setHeatmapColor(Color color) async {
    // Store as a hex string
    await _localStorageService.saveValue(
      StorageKeys.heatmapColorKey,
      color.toARGB32().toRadixString(16),
    );
  }
}
