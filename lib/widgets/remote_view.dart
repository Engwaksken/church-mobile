import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'ui.dart' show SkeletonList;

/// Loads data from the API and shows it, with a spinner, an error with Retry, and pull-to-refresh.
/// [builder] must return a scrollable widget (for example a ListView) so pull-to-refresh works.
class RemoteView extends StatefulWidget {
  const RemoteView({super.key, required this.load, required this.builder});

  final Future<Map<String, dynamic>> Function() load;
  final Widget Function(BuildContext context, Map<String, dynamic> data) builder;

  @override
  State<RemoteView> createState() => RemoteViewState();
}

class RemoteViewState extends State<RemoteView> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load this page.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonList();
    if (_data == null) {
      return MessageView(
        icon: Icons.cloud_off_outlined,
        message: _error ?? 'Could not load this page.',
        action: FilledButton.icon(onPressed: reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      );
    }
    return RefreshIndicator(
      onRefresh: reload,
      child: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [TextButton(onPressed: reload, child: const Text('Retry'))],
            ),
          Expanded(child: widget.builder(context, _data!)),
        ],
      ),
    );
  }
}

/// Centered icon and message, used for empty lists and errors.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Scrollable so pull-to-refresh still works on an empty page.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .55), shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: scheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16, height: 1.4)),
        if (action != null) ...[const SizedBox(height: 24), Center(child: action)],
      ],
    );
  }
}

/// Heading above a group of cards: a small accent mark, the title, and an optional action on the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.actionLabel, this.onAction});

  final String text;
  final Widget? trailing;

  /// Shortcut for a compact "See all" style link; ignored when [trailing] is given.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final action = trailing ??
        (actionLabel == null
            ? null
            : TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), visualDensity: VisualDensity.compact),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(actionLabel!), const SizedBox(width: 2), const Icon(Icons.chevron_right, size: 18)],
                ),
              ));
    return Padding(
      padding: EdgeInsets.fromLTRB(2, 22, 0, action == null ? 10 : 4),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
