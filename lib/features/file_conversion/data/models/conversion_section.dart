import 'package:flutter/material.dart';

class ConversionItem {
  final String title;
  final IconData icon;
  final Color color;

  const ConversionItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class ConversionSection {
  final String title;
  final List<ConversionItem> items;

  const ConversionSection({required this.title, required this.items});
}
