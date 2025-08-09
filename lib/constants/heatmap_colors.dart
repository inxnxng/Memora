import 'package:flutter/material.dart';

class HeatmapColor {
  final String name;
  final Color color;

  const HeatmapColor({required this.name, required this.color});
}

const List<HeatmapColor> heatmapColorOptions = [
  HeatmapColor(name: "GitHub Green", color: Color.fromARGB(255, 25, 192, 30)),
  HeatmapColor(name: "Mocha Mousse", color: Color(0xFF7B4F3E)),
  HeatmapColor(name: "Butter Yellow", color: Color(0xFFFFE08A)),
  HeatmapColor(name: "Cherry Red", color: Color(0xFFB22222)),
  HeatmapColor(name: "Aura Indigo", color: Color(0xFF6B5B95)),
];
