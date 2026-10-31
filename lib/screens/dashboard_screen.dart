import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/daily_verses.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/remote_view.dart';
import '../widgets/ui.dart';
import 'home_shell.dart';
import 'notifications_screen.dart';

/// Home: a daily page with a greeting, today's verse, shortcuts, what's next at church,
/// the member's pledge progress and the latest announcements.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenTab});

  /// Opens a section of the app (1 = Giving, 2 = Worship, 3 = Church), on an inner tab when given.
  final void Function(int section, [int? tab]) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final branding = session.branding;
    return Scaffold(
      appBar: BrandAppBar(
        leading: const MenuButton(),
        title: branding.name,
        subtitle: branding.subtitle,
        showLogo: true,
        rounded: false,
        actions: const [NotificationBell()],
      ),
      body: RemoteView(
        load: () => session.api.get('dashboard'),
        builder: (context, data) {
          final member = Map<String, dynamic>.from(
            data['member'] as Map? ?? session.member,
          );
          final verses = List<Map<String, dynamic>>.from(
            data['verses'] as List? ?? [],
          );
          final pledges = Map<String, dynamic>.from(
            data['pledges'] as Map? ?? {},
          );
          final announcements = List<Map<String, dynamic>>.from(
            data['announcements'] as List? ?? [],
          );
          final programs = List<Map<String, dynamic>>.from(
            data['programs'] as List? ?? [],
          );
          const side = EdgeInsets.symmetric(horizontal: AppSpace.page);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Header(
                member: member,
                hero: verses.isEmpty
                    ? const _VerseCard.local()
                    : _VerseCard(verse: verses.first),
              ),
              Padding(
                padding: side,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    _QuickActions(open: onOpenTab),
                    SectionTitle(
                      'Up next',
                      actionLabel: 'All programs',
                      onAction: () => onOpenTab(3, 1),
                    ),
                    if (programs.isEmpty)
                      const EmptyNote(
                        icon: Icons.event_busy,
                        text: 'No upcoming programs.',
                      ),
                    for (final (i, p) in programs.indexed)
                      _ProgramCard(
                        program: p,
                        featured: i == 0,
                        onTap: () => onOpenTab(3, 1),
                      ),
                    SectionTitle(
                      'My pledges',
                      actionLabel: 'View',
                      onAction: () => onOpenTab(1, 0),
                    ),
                    _PledgeSummary(
                      pledges: pledges,
                      onTap: () => onOpenTab(1, 0),
                    ),
                    SectionTitle(
                      'Announcements',
                      actionLabel: 'All',
                      onAction: () => onOpenTab(3, 0),
                    ),
                    if (announcements.isEmpty)
                      const EmptyNote(
                        icon: Icons.notifications_none,
                        text: 'No announcements right now.',
                      ),
                    for (final a in announcements)
                      _AnnouncementCard(
                        announcement: a,
                        onTap: () => onOpenTab(3, 0),
                      ),
                    if (verses.length > 1) ...[
                      const SectionTitle('More scripture'),
                      for (final v in verses.skip(1))
                        _VerseCard(verse: v, compact: true),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Good morning" for the hour of [now].
String _timeOfDayGreeting(DateTime now) => switch (now.hour) {
  < 12 => 'Good morning',
  < 17 => 'Good afternoon',
  _ => 'Good evening',
};

/// Brand panel that continues the app bar, with the greeting and the "Today" card overlapping its edge.
class _Header extends StatelessWidget {
  const _Header({required this.member, required this.hero});

  final Map<String, dynamic> member;
  final Widget hero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = AppTones.on(scheme.primary);
    final now = DateTime.now();
    final firstName = asText(member['full_name'], 'Member').split(' ').first;
    Widget tag(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg.withValues(alpha: .9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTones.brand(scheme.primary),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.header + 6),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_timeOfDayGreeting(now)} · ${formatDate(now.toIso8601String(), 'EEEE, d MMMM')}'
                        .toUpperCase(),
                    style: TextStyle(
                      color: fg.withValues(alpha: .8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .9,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome back, $firstName',
                    style: TextStyle(
                      color: fg,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      tag(
                        Icons.badge_outlined,
                        'Member No: ${asText(member['member_no'], '-')}',
                      ),
                      if (asText(member['pledge_no']).isNotEmpty)
                        tag(
                          Icons.handshake_outlined,
                          'Pledge No: ${member['pledge_no']}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: hero,
            ),
          ],
        ),
      ],
    );
  }
}

/// Scripture card. The first verse from the church is the "Today" hero; when there is none, a
/// verse from the local daily rotation is shown instead. The hero card collapses to a short
/// preview; tapping it (or the chevron) expands the full verse.
class _VerseCard extends StatefulWidget {
  const _VerseCard({
    required Map<String, dynamic> this.verse,
    this.compact = false,
  });

  const _VerseCard.local() : verse = null, compact = false;

  final Map<String, dynamic>? verse;
  final bool compact;

  @override
  State<_VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<_VerseCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = widget.verse;
    final compact = widget.compact;
    final local = v == null ? verseForDay() : null;
    final text = local?.text ?? asText(v?['verse_text']);
    final translation = local == null ? asText(v?['translation']) : 'KJV';
    final reference = local?.reference ?? asText(v?['reference']);
    final citation = translation.isEmpty
        ? reference
        : '$reference ($translation)';
    final isToday =
        v != null &&
        asText(v['display_date']) ==
            DateTime.now().toIso8601String().substring(0, 10);
    final heading = local != null
        ? "TODAY'S SCRIPTURE"
        : (isToday ? 'VERSE OF THE DAY' : 'BIBLE VERSE');
    final accent = scheme.secondary;

    if (compact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '— $citation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .16),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _toggle,
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -26,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 120,
                  color: accent.withValues(alpha: .12),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 5, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 8, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          color: AppTones.deep(accent),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            heading,
                            style: TextStyle(
                              color: AppTones.deep(accent),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy verse',
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: '$text\n— $citation'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verse copied')),
                            );
                          },
                        ),
                        Semantics(
                          button: true,
                          expanded: _expanded,
                          child: IconButton(
                            key: const Key('verseToggle'),
                            tooltip: _expanded
                                ? 'Collapse verse'
                                : 'Expand verse',
                            onPressed: _toggle,
                            icon: AnimatedRotation(
                              turns: _expanded ? .5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppTones.deep(accent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              maxLines: _expanded ? null : 2,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18.5,
                                fontStyle: FontStyle.italic,
                                height: 1.55,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '— $citation',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                fontSize: 14.5,
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
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.open});

  final void Function(int section, [int? tab]) open;

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickAction(
        icon: Icons.volunteer_activism_outlined,
        label: 'Giving',
        accent: true,
        onTap: () => open(1, 0),
      ),
      QuickAction(
        icon: Icons.library_music_outlined,
        label: 'Songs',
        onTap: () => open(2, 1),
      ),
      QuickAction(
        icon: Icons.list_alt_outlined,
        label: 'Service',
        onTap: () => open(2, 0),
      ),
      QuickAction(
        icon: Icons.event_outlined,
        label: 'Programs',
        accent: true,
        onTap: () => open(3, 1),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: a),
        ],
      ],
    );
  }
}

class _PledgeSummary extends StatelessWidget {
  const _PledgeSummary({required this.pledges, required this.onTap});

  final Map<String, dynamic> pledges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pledged = asDouble(pledges['total_pledged']);
    final paid = asDouble(pledges['total_paid']);
    if (pledged <= 0) {
      return const EmptyNote(
        icon: Icons.handshake_outlined,
        text: 'You have no pledges recorded.',
      );
    }
    final progress = (paid / pledged).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final percent = (progress * 100).round();
    return TapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: '$percent percent of pledges paid',
                excludeSemantics: true,
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: scheme.primary.withValues(alpha: .1),
                      ),
                      Center(
                        child: Text(
                          '$percent%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid so far',
                      style: TextStyle(color: muted, fontSize: 13.5),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ugx(paid),
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 22),
                      ),
                    ),
                    if (asDouble(pledges['open']) > 0)
                      Text(
                        '${asDouble(pledges['open']).round()} open pledge${asDouble(pledges['open']).round() == 1 ? '' : 's'}',
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Figure(label: 'Pledged', value: ugx(pledged)),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: scheme.primary.withValues(alpha: .12),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Figure(
                    label: 'Balance',
                    value: ugx(pledges['balance']),
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

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final Map<String, dynamic> announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priority = asText(announcement['priority']);
    final scheme = Theme.of(context).colorScheme;
    final date = formatDate(announcement['published_at']);
    return TapCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnnouncementIcon(priority),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      asText(announcement['title']),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ?Pill.priority(priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  asText(announcement['message']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (date != '-') ...[
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.featured,
    required this.onTap,
  });

  final Map<String, dynamic> program;
  final bool featured;
  final VoidCallback onTap;

  /// "Today", "Tomorrow" or "In 3 days" for a program within the coming week.
  static String? _countdown(Object? date) {
    final parsed = DateTime.tryParse(asText(date));
    if (parsed == null) return null;
    final now = DateTime.now();
    final days = DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      > 1 && < 7 => 'In $days days',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = program;
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      formatDate(p['program_date'], 'EEEE'),
      formatTime(p['start_time']),
      asText(p['venue']),
    ].where((s) => s.isNotEmpty && s != '-').join(' · ');
    final countdown = featured ? _countdown(p['program_date']) : null;
    return TapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: featured ? scheme.secondary.withValues(alpha: .55) : null,
      child: Row(
        children: [
          DateBadge(p['program_date']),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (countdown != null) ...[
                  Pill(
                    countdown,
                    color: AppTones.soft(scheme.secondary),
                    textColor: AppTones.deep(scheme.secondary),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  asText(p['title']),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
