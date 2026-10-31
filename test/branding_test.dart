import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentecostal_app/core/branding.dart';
import 'package:pentecostal_app/core/theme.dart';

void main() {
  test('parses administrator branding and validates color values', () {
    final branding = ChurchBranding.fromJson({
      'name': 'Pentecostal Church',
      'subtitle': 'Growing in faith',
      'logo_url': 'https://example.test/logo.png',
      'colors': {
        'primary': '#123456',
        'secondary': '#abcdef',
        'background': '#f0f0f0',
        'text': 'not-a-color',
      },
    });

    expect(branding.name, 'Pentecostal Church');
    expect(branding.subtitle, 'Growing in faith');
    expect(branding.logoUrl, 'https://example.test/logo.png');
    expect(branding.primary, const Color(0xFF123456));
    expect(branding.secondary, const Color(0xFFABCDEF));
    expect(branding.background, const Color(0xFFF0F0F0));
    expect(branding.text, const Color(0xFF1E1E2D));
  });

  test('applies administrator colors to the app theme', () {
    const branding = ChurchBranding(
      primary: Color(0xFF123456),
      secondary: Color(0xFFABCDEF),
      background: Color(0xFFF0F0F0),
      text: Color(0xFF101010),
    );
    final theme = buildAppTheme(branding);

    expect(theme.colorScheme.primary, branding.primary);
    expect(theme.colorScheme.secondary, branding.secondary);
    expect(theme.scaffoldBackgroundColor, branding.background);
    expect(theme.colorScheme.onSurface, branding.text);
  });
}
