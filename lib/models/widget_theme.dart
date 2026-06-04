import 'package:flutter/material.dart';

class WidgetTheme {
  final int index;
  final String name;
  final Color accentColor;

  const WidgetTheme({
    required this.index,
    required this.name,
    required this.accentColor,
  });

  static const List<WidgetTheme> themes = [
    WidgetTheme(index: 0, name: 'Frost', accentColor: Color(0xFF4f6ef7)),
    WidgetTheme(index: 1, name: 'Midnight', accentColor: Color(0xFF6B8AFF)),
    WidgetTheme(index: 2, name: 'Emerald', accentColor: Color(0xFF4ADE80)),
    WidgetTheme(index: 3, name: 'Rose', accentColor: Color(0xFFF472B6)),
    WidgetTheme(index: 4, name: 'Amber', accentColor: Color(0xFFFBBF24)),
  ];

  String get drawableName => 'widget_glass_bg_${name.toLowerCase()}';

  static WidgetTheme fromIndex(int index) {
    if (index < 0 || index >= themes.length) return themes[0];
    return themes[index];
  }
}
