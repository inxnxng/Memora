import 'package:flutter/material.dart';

class HeatmapColor {
  final String name;
  final Color color;

  const HeatmapColor({required this.name, required this.color});
}

const List<HeatmapColor> heatmapColorOptions = [
  HeatmapColor(name: "GitHub Green", color: Color(0xFF39D353)),
  HeatmapColor(name: "Future Dusk", color: Color(0xFF272838)),
  HeatmapColor(
    name: "Mocha Mousse",
    color: Color(0xFF7B4F3E),
  ), // Pantone 17‑1230
  HeatmapColor(
    name: "Butter Yellow",
    color: Color(0xFFFFE08A),
  ), // Soft yellow 계열
  HeatmapColor(name: "Cherry Red", color: Color(0xFFB22222)), // 트렌드 레드
  HeatmapColor(name: "Aura Indigo", color: Color(0xFF6B5B95)), // 퍼플 블루 톤
];
