import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'church_logo.dart';

/// Branded page for signed-out screens: a purple header with the crest, then a white sheet for the form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.compact = false,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool compact;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final logo = compact ? 56.0 : 80.0;
    final session = context.watch<Session>();
    final scheme = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppTones.brand(scheme.primary),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  top + (showBack ? 4 : 28),
                  24,
                  48,
                ),
                child: Column(
                  children: [
                    if (showBack)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(color: Colors.white),
                      ),
                    Container(
                      padding: EdgeInsets.all(compact ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ChurchLogo(
                        url: session.branding.logoUrl,
                        size: logo,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Purple gradient panel, used for the home greeting and giving totals.
class BrandPanel extends StatelessWidget {
  const BrandPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppTones.brand(primary),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: AppTones.on(primary)),
        child: IconTheme.merge(
          data: IconThemeData(color: AppTones.on(primary)),
          child: child,
        ),
      ),
    );
  }
}

/// Icon on a soft tinted square, leading list items.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.color,
    this.background,
    this.size = 44,
  });

  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: color ?? scheme.primary, size: size * .52),
    );
  }
}

/// Megaphone badge for an announcement, red when urgent.
class AnnouncementIcon extends StatelessWidget {
  const AnnouncementIcon(this.priority, {super.key});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = priority == 'Urgent';
    return IconBadge(
      Icons.campaign_outlined,
      color: urgent ? scheme.error : null,
      background: urgent ? scheme.errorContainer : null,
    );
  }
}

/// Day and month on a tinted tile, leading a program.
class DateBadge extends StatelessWidget {
  const DateBadge(this.date, {super.key});

  final Object? date;

  @override
  Widget build(BuildContext context) {
    final day = formatDate(date, 'd');
    if (day == '-') return const IconBadge(Icons.event_outlined, size: 52);
    final secondary = Theme.of(context).colorScheme.secondary;
    final ink = AppTones.deep(secondary);
    return Container(
      constraints: const BoxConstraints(minWidth: 52, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppTones.soft(secondary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDate(date, 'MMM').toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: .6,
            ),
          ),
          Text(
            day,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ink,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded label, for priorities and statuses.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.textColor});

  final String label;
  final Color? color;
  final Color? textColor;

  /// Announcement priority; null for normal priority.
  static Pill? priority(String priority) => switch (priority) {
    '' || 'Normal' => null,
    'Urgent' => Pill(
      priority,
      color: const Color(0xFFFDE2E1),
      textColor: const Color(0xFFB3261E),
    ),
    _ => Pill(
      priority,
      color: AppColors.goldSoft,
      textColor: AppColors.goldText,
    ),
  };

  /// Pledge status, green when settled and red when overdue or cancelled.
  static Pill status(String status) {
    final s = status.toLowerCase();
    if (['complet', 'fulfil', 'paid', 'clear'].any(s.contains)) {
      return Pill(
        status,
        color: AppColors.successSoft,
        textColor: AppColors.success,
      );
    }
    if (['overdue', 'cancel', 'default'].any(s.contains)) {
      return Pill(
        status,
        color: const Color(0xFFFDE2E1),
        textColor: const Color(0xFFB3261E),
      );
    }
    return Pill(status);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textColor ?? scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Quiet card for an empty section inside a longer page.
class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: muted)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label above a value, for detail lists.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconBadge(icon, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand-gradient app bar shared by the main tabs, with the church name under the title and
/// optional pill-style tabs. Colors follow the branding set on the church website.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.tabs,
    this.scrollableTabs = false,
    this.rounded = true,
    this.showLogo = false,
  });

  final String title;

  /// Line under the title; defaults to the church name, '' hides it.
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  /// Labels for a TabBar in the header (needs a DefaultTabController above).
  final List<String>? tabs;
  final bool scrollableTabs;

  /// Rounds the bottom corners; turn off when a panel continues the gradient below.
  final bool rounded;

  /// Shows the church logo before the title.
  final bool showLogo;

  static const _tabsHeight = 58.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (tabs == null ? 0 : _tabsHeight));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final branding = context.watch<Session>().branding;
    final fg = AppTones.on(scheme.primary);
    final line = subtitle ?? branding.name;
    final radius = rounded
        ? const BorderRadius.vertical(bottom: Radius.circular(AppRadius.header))
        : BorderRadius.zero;
    final tabs = this.tabs;
    return AppBar(
      leading: leading,
      titleSpacing: leading == null ? null : 4,
      backgroundColor: Colors.transparent,
      foregroundColor: fg,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      systemOverlayStyle: fg == Colors.white
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      // A Container (not a DecoratedBox) so the gradient fills the whole bar.
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTones.brand(scheme.primary),
          borderRadius: radius,
        ),
      ),
      actions: [...actions, const SizedBox(width: 4)],
      title: Row(
        children: [
          if (showLogo) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ChurchLogo(url: branding.logoUrl, size: 28),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontSize: line.isEmpty ? 21 : 19,
                  ),
                ),
                if (line.isNotEmpty)
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg.withValues(alpha: .78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottom: tabs == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(_tabsHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: _HeaderTabs(
                  labels: tabs,
                  scrollable: scrollableTabs,
                  foreground: fg,
                ),
              ),
            ),
    );
  }
}

/// Segmented, pill-style tabs that sit on the brand gradient.
class _HeaderTabs extends StatelessWidget {
  const _HeaderTabs({
    required this.labels,
    required this.scrollable,
    required this.foreground,
  });

  final List<String> labels;
  final bool scrollable;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final selectedText =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? primary
        : AppTones.deep(primary);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: selectedText,
        unselectedLabelColor: foreground.withValues(alpha: .88),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        splashBorderRadius: BorderRadius.circular(11),
        overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: .08)),
        tabs: [for (final l in labels) Tab(text: l, height: 38)],
      ),
    );
  }
}

/// Round member photo with a ring in the church's accent color, falling back to an initial.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    this.radius = 30,
  });

  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(radius > 36 ? 3 : 2.5),
      decoration: BoxDecoration(
        color: scheme.secondary,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        foregroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
        child: Text(
          name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: radius * .8,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Card that can be tapped, with the app's standard padding and ripple.
class TapCard extends StatelessWidget {
  const TapCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = this.borderColor;
    return Card(
      color: color,
      shape: borderColor == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: borderColor),
            ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Square shortcut with a tinted icon and a short label, for the home quick actions.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Uses the secondary (accent) brand color instead of the primary.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = accent ? scheme.secondary : scheme.primary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.primary.withValues(alpha: .08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTones.soft(tone),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: accent ? AppTones.deep(tone) : tone,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gently pulsing placeholder cards, shown while a page loads.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.cards = 4});

  final int cards;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = Theme.of(context).colorScheme.primary.withValues(alpha: .07);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.page),
        children: [
          FadeTransition(
            opacity: Tween(begin: .45, end: 1.0).animate(_pulse),
            child: Column(
              children: [
                for (var i = 0; i < widget.cards; i++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: block,
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bar(i.isEven ? 180 : 140, 14),
                                const SizedBox(height: 10),
                                bar(double.infinity, 11),
                                const SizedBox(height: 6),
                                bar(i.isEven ? 120 : 160, 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
