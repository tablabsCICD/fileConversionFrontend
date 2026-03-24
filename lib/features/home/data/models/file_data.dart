import 'package:flutter/material.dart';

class FileData {
  final String name;
  final String size;
  final String type;
  final IconData icon;
  final Color color;

  const FileData({
    required this.name,
    required this.size,
    required this.type,
    required this.icon,
    required this.color,
  });
}
