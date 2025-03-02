import 'package:flutter/material.dart';

class CustomMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<CustomMenuItem>? children;
  
  CustomMenuItem({
    required this.title, 
    required this.icon, 
    required this.route, 
    this.children,
  });
}
