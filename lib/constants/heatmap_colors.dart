import 'package:flutter/material.dart';

class HeatmapColor {
  final String name;
  final Color color;

  const HeatmapColor({required this.name, required this.color});
}

const List<HeatmapColor> heatmapColorOptions = [
  HeatmapColor(name: 'GitHub Green', color: Color(0xFF39D353)),
  HeatmapColor(name: 'Sakura Pink', color: Colors.pinkAccent),
  HeatmapColor(name: 'Burgundy', color: Color(0xFF800020)),
  HeatmapColor(name: 'Future Dusk', color: Color(0xFF272838)),
];
