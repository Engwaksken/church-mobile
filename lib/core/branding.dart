import 'package:flutter/material.dart';

/// Branding configured by an administrator in the church website settings.
@immutable
class ChurchBranding {
  const ChurchBranding({
    this.name = 'Pentecostal Church',
    this.subtitle = '',
    this.logoUrl = '',
    this.primary = const Color(0xFF4A1E8F),
    this.secondary = const Color(0xFFD4A017),
    this.background = const Color(0xFFF3F2F8),
    this.text = const Color(0xFF1E1E2D),
  });

  final String name;
  final String subtitle;
  final String logoUrl;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color text;

  factory ChurchBranding.fromJson(Map<String, dynamic> json) {
    final colors = Map<String, dynamic>.from(json['colors'] as Map? ?? {});
    return ChurchBranding(
      name: _string(json['name'], 'Pentecostal Church'),
      subtitle: _string(json['subtitle']),
      logoUrl: _string(json['logo_url']),
      primary: _color(colors['primary'], const Color(0xFF4A1E8F)),
      secondary: _color(colors['secondary'], const Color(0xFFD4A017)),
      background: _color(colors['background'], const Color(0xFFF3F2F8)),
      text: _color(colors['text'], const Color(0xFF1E1E2D)),
    );
  }

  static String _string(Object? value, [String fallback = '']) =>
      value is String ? value.trim() : fallback;

  static Color _color(Object? value, Color fallback) {
    if (value is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return fallback;
    }
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }
}
