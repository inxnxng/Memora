import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/services/local_storage_service.dart';

class SettingsService {
  final LocalStorageService _localStorageService;

  SettingsService(this._localStorageService);

  // Heatmap Color
  Future<String> getHeatmapColorName() async {
    return await _localStorageService.getValue(kHeatmapColorKey) ??
        kDefaultHeatmapColor;
  }

  Future<void> setHeatmapColorName(String colorName) async {
    await _localStorageService.saveValue(kHeatmapColorKey, colorName);
  }
}
