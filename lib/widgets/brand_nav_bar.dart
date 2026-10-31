import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// One destination in [BrandNavBar].
class BrandNavItem {
  const BrandNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating, rounded bottom bar in the church's brand colors.
///
/// Every destination keeps its label. The selected one gets a tinted pill behind a filled icon, and
/// the destination at [centerIndex] is a raised brand-gradient button. Colors come from the theme,
/// so they follow the branding set on the church website.
class BrandNavBar extends StatelessWidget {
  const BrandNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.centerIndex,
  });

  final List<BrandNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Destination shown as a raised round button, or null for none.
  final int? centerIndex;

  /// Height of the bar itself, and how far the center button rises above it.
  static const barHeight = 66.0;
  static const _rise = 18.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inset = MediaQuery.paddingOf(context).bottom;
    // Keep labels readable with large text without letting them burst out of the bar.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, inset > 0 ? inset : 12),
        child: SizedBox(
          height: barHeight + _rise,
          child: Stack(
            children: [
              Positioned.fill(
                top: _rise,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(barHeight / 2.4),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: .08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: .14),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (final (i, item) in items.indexed)
                      Expanded(
                        child: _Destination(
                          item: item,
                          selected: i == selectedIndex,
                          raised: i == centerIndex,
                          position: i + 1,
                          count: items.length,
                          onTap: () {
                            if (i != selectedIndex) {
                              HapticFeedback.selectionClick();
                            }
                            onSelected(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.raised,
    required this.position,
    required this.count,
    required this.onTap,
  });

  final BrandNavItem item;
  final bool selected;
  final bool raised;
  final int position;
  final int count;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    final label = AnimatedDefaultTextStyle(
      duration: _duration,
      curve: Curves.easeOut,
      style: TextStyle(
        fontSize: 12,
        height: 1.2,
        letterSpacing: .1,
        color: color,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(item.label, maxLines: 1),
      ),
    );

    final Widget content;
    if (raised) {
      final onBrand = AppTones.on(scheme.primary);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 3),
          AnimatedScale(
            duration: _duration,
            curve: Curves.easeOutBack,
            scale: selected ? 1.06 : 1,
            child: AnimatedContainer(
              duration: _duration,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTones.brand(scheme.primary),
                border: Border.all(
                  color: selected ? scheme.secondary : scheme.surface,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: .35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: onBrand,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 3),
          label,
        ],
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.only(top: BrandNavBar._rise),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              width: selected ? 56 : 40,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: .12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            label,
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      hint: 'Tab $position of $count',
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox.expand(child: content),
        ),
      ),
    );
  }
}
