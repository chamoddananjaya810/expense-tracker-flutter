import 'package:flutter/material.dart';

/// Small value type pairing an icon + accent color for a category.
class CategoryInfo {
  final IconData icon;
  final Color color;
  const CategoryInfo(this.icon, this.color);
}

/// Central place to define how each category looks across the whole app.
/// Add a new category here and every screen (list, form, summary chart)
/// picks it up automatically.
const Map<String, CategoryInfo> kCategoryInfo = {
  'Food': CategoryInfo(Icons.restaurant_rounded, Color(0xFFFF9F43)),
  'Travel': CategoryInfo(Icons.flight_takeoff_rounded, Color(0xFF3B82F6)),
  'Bills': CategoryInfo(Icons.receipt_long_rounded, Color(0xFFEF4444)),
  'Shopping': CategoryInfo(Icons.shopping_bag_rounded, Color(0xFFA855F7)),
  'Health': CategoryInfo(Icons.health_and_safety_rounded, Color(0xFF22C55E)),
  'Other': CategoryInfo(Icons.category_rounded, Color(0xFF6B7280)),
};

const List<String> kCategories = [
  'Food',
  'Travel',
  'Bills',
  'Shopping',
  'Health',
  'Other',
];

CategoryInfo categoryInfoFor(String category) =>
    kCategoryInfo[category] ??
    const CategoryInfo(Icons.category_rounded, Color(0xFF6B7280));
