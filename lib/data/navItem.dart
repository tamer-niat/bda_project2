import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  final int page;
  final String? description;

  NavItem({
    required this.icon,
    required this.label,
    required this.page,
    this.description,
  });
}