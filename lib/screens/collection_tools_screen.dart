import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../widgets/remote_view.dart';

/// Finance collection entry points are returned by the server only for assigned permissions.
class CollectionToolsScreen extends StatefulWidget {
  const CollectionToolsScreen({super.key});

  @override
  State<CollectionToolsScreen> createState() => _CollectionToolsScreenState();
}

class _CollectionToolsScreenState extends State<CollectionToolsScreen> {
  late final ApiClient _api = context.read<Session>().api;
  late Future<Map<String, dynamic>> _future = _api.get('role_tools');

  static const _labels = <String, (String, IconData)>{
    'offertory': ('Record offertory', Icons.volunteer_activism_outlined),
    'tithe': ('Record tithe', Icons.percent),
    'thanksgiving': ('Record thanksgiving', Icons.celebration_outlined),
    'pledge_payment': ('Record pledge payment', Icons.handshake_outlined),
    'contribution': ('Record contribution', Icons.savings_outlined),
    'good_samaritan': ('Record Good Samaritan', Icons.favorite_border),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Role Tasks')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return MessageView(icon: Icons.cloud_off_outlined, message: snapshot.error.toString(), action: FilledButton.icon(onPressed: () => setState(() => _future = _api.get('role_tools')), icon: const Icon(Icons.refresh), label: const Text('Retry')));
            final data = snapshot.data ?? {};
            final tools = List<String>.from(data['items'] as List? ?? []);
            if (tools.isEmpty) return const MessageView(icon: Icons.admin_panel_settings_outlined, message: 'No collection tasks are assigned to your account. Ask a church administrator to assign the appropriate finance permission.');
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Assigned collection tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                const Text('Choose a task to record a collection. Access is based on your church account permissions.'),
                const SizedBox(height: 14),
                for (final type in tools.where(_labels.containsKey))
                  Card(child: ListTile(
                    leading: Icon(_labels[type]!.$2),
                    title: Text(_labels[type]!.$1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _record(type, data),
                  )),
              ],
            );
          },
        ),
      );

  Future<void> _record(String type, Map<String, dynamic> data) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CollectionForm(api: _api, type: type, options: data),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collection recorded successfully.')));
      setState(() => _future = _api.get('role_tools'));
    }
  }
}

class _CollectionForm extends StatefulWidget {
  const _CollectionForm({required this.api, required this.type, required this.options});
  final ApiClient api;
  final String type;
  final Map<String, dynamic> options;

  @override
  State<_CollectionForm> createState() => _CollectionFormState();
}

class _CollectionFormState extends State<_CollectionForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _envelope = TextEditingController();
  final _loose = TextEditingController();
  final _extra = TextEditingController();
  final _notes = TextEditingController();
  final _reason = TextEditingController();
  final _item = TextEditingController();
  final _giver = TextEditingController();
  final _date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _method = 'Cash';
  String _service = 'Sunday Service';
  String? _memberId;
  String? _projectId;
  String? _pledgeId;
  bool _saving = false;

  List<Map<String, dynamic>> get _members => List<Map<String, dynamic>>.from(widget.options['members'] as List? ?? []);
  List<Map<String, dynamic>> get _projects => List<Map<String, dynamic>>.from(widget.options['projects'] as List? ?? []);
  List<Map<String, dynamic>> get _pledges => List<Map<String, dynamic>>.from(widget.options['pledges'] as List? ?? []);
  bool get _isOffertory => widget.type == 'offertory';

  @override
  void dispose() {
    for (final c in [_amount, _envelope, _loose, _extra, _notes, _reason, _item, _giver, _date]) { c.dispose(); }
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;
  Widget _moneyField(String label, TextEditingController controller, {bool required = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, prefixText: 'UGX ', border: const OutlineInputBorder()),
          validator: required ? (v) { if (_required(v) != null) return 'Enter an amount'; if ((double.tryParse(v!) ?? 0) <= 0) return 'Amount must be greater than zero'; return null; } : null,
        ),
      );

  Widget _memberDropdown({bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: _memberId,
          decoration: const InputDecoration(labelText: 'Member (optional)', border: OutlineInputBorder()),
          items: [if (!required) const DropdownMenuItem(value: '', child: Text('General / not listed')), ..._members.map((m) => DropdownMenuItem(value: '${m['id']}', child: Text('${m['full_name']} · ${m['member_no']}')))],
          onChanged: (v) => setState(() => _memberId = v),
          validator: required ? (v) => v == null || v.isEmpty ? 'Select a member' : null : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title = _CollectionToolsScreenState._labels[widget.type]?.$1 ?? 'Record collection';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(child: Form(key: _form, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(controller: _date, readOnly: true, decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(_date.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (picked != null) _date.text = picked.toIso8601String().substring(0, 10);
          }),
          const SizedBox(height: 12),
          if (_isOffertory) ...[
            DropdownButtonFormField<String>(initialValue: _service, decoration: const InputDecoration(labelText: 'Service', border: OutlineInputBorder()), items: ['Sunday Service','Wednesday Bible Study','Friday Prayer','Special Service','Revival','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _service = v ?? _service)),
            const SizedBox(height: 12),
            _moneyField('Envelope collection', _envelope, required: false),
            _moneyField('Loose offering', _loose, required: false),
            _moneyField('Other / additional', _extra, required: false),
          ] else if (widget.type == 'pledge_payment') ...[
            DropdownButtonFormField<String>(initialValue: _pledgeId, decoration: const InputDecoration(labelText: 'Pledge', border: OutlineInputBorder()), items: _pledges.map((p) => DropdownMenuItem(value: '${p['id']}', child: Text('${p['pledge_no']} · ${asText(p['pledge_reason'], 'Pledge')} · Balance ${ugx(asDouble(p['amount_pledged']) - asDouble(p['amount_paid']))}'))).toList(), onChanged: (v) => setState(() => _pledgeId = v), validator: (v) => v == null ? 'Select a pledge' : null),
            const SizedBox(height: 12),
            _moneyField('Payment amount', _amount),
          ] else ...[
            _moneyField('Amount', _amount),
            if (widget.type == 'tithe' || widget.type == 'good_samaritan') _memberDropdown(),
            if (widget.type == 'thanksgiving') ...[
              _memberDropdown(),
              TextFormField(controller: _giver, decoration: const InputDecoration(labelText: 'Giver name (if not selecting a member)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _reason, decoration: const InputDecoration(labelText: 'Thanksgiving reason', border: OutlineInputBorder()), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _item, decoration: const InputDecoration(labelText: 'Item description (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
            ],
            if (widget.type == 'contribution') ...[
              _memberDropdown(required: true),
              DropdownButtonFormField<String>(initialValue: _projectId, decoration: const InputDecoration(labelText: 'Project', border: OutlineInputBorder()), items: _projects.map((p) => DropdownMenuItem(value: '${p['id']}', child: Text(asText(p['name'])))).toList(), onChanged: (v) => setState(() => _projectId = v), validator: (v) => v == null ? 'Select a project' : null),
              const SizedBox(height: 12),
            ],
          ],
          DropdownButtonFormField<String>(initialValue: _method, decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder()), items: ['Cash','Mobile Money','Bank Transfer','Cheque','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _method = v ?? _method)),
          const SizedBox(height: 12),
          TextFormField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _saving ? null : _submit, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Record collection')),
        ],
      ))),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final amount = _isOffertory ? (double.tryParse(_envelope.text) ?? 0) + (double.tryParse(_loose.text) ?? 0) + (double.tryParse(_extra.text) ?? 0) : double.tryParse(_amount.text) ?? 0;
    if (_isOffertory && amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter at least one offertory amount.'))); return; }
    final body = <String, dynamic>{'type': widget.type, 'amount': amount, 'date': _date.text, 'method': _method, 'notes': _notes.text};
    if (_memberId != null && _memberId!.isNotEmpty) body['member_id'] = int.parse(_memberId!);
    if (_isOffertory) body.addAll({'envelope_total': double.tryParse(_envelope.text) ?? 0, 'loose_total': double.tryParse(_loose.text) ?? 0, 'extra': double.tryParse(_extra.text) ?? 0, 'service_type': _service});
    if (widget.type == 'tithe') { body['period_month'] = int.parse(_date.text.substring(5, 7)); body['period_year'] = int.parse(_date.text.substring(0, 4)); }
    if (widget.type == 'thanksgiving') body.addAll({'giver_name': _giver.text, 'reason': _reason.text, 'item_description': _item.text});
    if (widget.type == 'contribution') body['project_id'] = int.parse(_projectId!);
    if (widget.type == 'pledge_payment') body['pledge_id'] = int.parse(_pledgeId!);
    setState(() => _saving = true);
    try {
      final result = await widget.api.post('record_collection', body);
      if (mounted) Navigator.pop(context, result['success'] == true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally { if (mounted) setState(() => _saving = false); }
  }
}
