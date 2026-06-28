import 'package:flutter/material.dart';

// Blood Donation Theme Colors
const primaryColor = Color(0xFFDC143C); // Crimson Red
const secondaryColor = Color(0xFFFFFFFF); // White for cards
const bgColor = Color(0xFFFFF5F5); // Very light pink/white
const cardBgColor = Color(0xFFFFFFFF); // Pure white for cards
const darkRedColor = Color(0xFF8B0000); // Dark red for sidebar
const lightRedColor = Color(0xFFFFE4E4); // Light pink for highlights
const accentRedColor = Color(0xFFFF6B6B); // Coral Red for accents

// New accent colors for visual depth
const tealAccent = Color(0xFF14B8A6); // Teal for highlights
const orangeAccent = Color(0xFFFF8C42); // Orange for secondary accents
const grayColor = Color(0xFF64748B); // Slate gray for text
const lightGrayColor = Color(0xFFF1F5F9); // Light gray for backgrounds
const shadowColor = Color(0x1A000000); // Subtle shadow

const defaultPadding = 16.0;

// Mapbox Configuration
// Provide this at runtime with --dart-define=MAPBOX_ACCESS_TOKEN=...
const String mapboxPublicToken = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  defaultValue: '',
);
