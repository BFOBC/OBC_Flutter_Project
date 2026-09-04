import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/models/TemplateModel.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/UpperCaseTextFormatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ManageTemplatesScreen extends StatefulWidget {
  const ManageTemplatesScreen({super.key});

  @override
  State<ManageTemplatesScreen> createState() => _ManageTemplatesScreenState();
}

class _ManageTemplatesScreenState extends State<ManageTemplatesScreen> {
  final List<String> _units = ['kg', 'g', 'lb', 'ton'];
  final List<String> _currencies = ['USD', 'EUR'];

  Stream<QuerySnapshot> _templatesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('broker_templates')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('broker_templates')
          .doc(id)
          .delete();
      Fluttertoast.showToast(
          msg: 'Template deleted',
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  void _openTemplateForm({TemplateModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateFormSheet(
        existing: existing,
        units: _units,
        currencies: _currencies,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Templates',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Palette.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTemplateForm(),
        backgroundColor: Palette.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Template',
            style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _templatesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Palette.primaryColor));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No templates yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Text('Tap + to create your first template',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            );
          }
          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = TemplateModel.fromMap(
                  docs[i].id, docs[i].data() as Map<String, dynamic>);
              return _TemplateCard(
                template: t,
                onEdit: () => _openTemplateForm(existing: t),
                onDelete: () =>
                    _confirmDelete(t.templateId!, t.templateName),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Template Card ─────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final TemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard(
      {required this.template,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    color: Palette.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(template.templateName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Palette.primaryColor, size: 20),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
            const Divider(height: 14),
            _row(Icons.flight_takeoff, 'From', template.departureFrom),
            _row(Icons.flight_land, 'To', template.arriveAt),
            _row(Icons.attach_money, 'Bid',
                '${template.bid} ${template.currency}'),
            _row(Icons.inventory_2_outlined, 'Capacity',
                '${template.courierCapacity} ${template.unit}'),
            if (template.milestones.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.flag_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('${template.milestones.length} milestone(s)',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text('$label: ',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

// ── Milestone entry ───────────────────────────────────────────────────────────

class _MilestoneEntry {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;

  _MilestoneEntry()
      : titleCtrl = TextEditingController(),
        descCtrl = TextEditingController(),
        startCtrl = TextEditingController(),
        endCtrl = TextEditingController();

  _MilestoneEntry.prefilled(
      String title, String desc, String start, String end)
      : titleCtrl = TextEditingController(text: title),
        descCtrl = TextEditingController(text: desc),
        startCtrl = TextEditingController(text: start),
        endCtrl = TextEditingController(text: end);

  DateTime? get startDate => startCtrl.text.isEmpty
      ? null
      : DateTime.tryParse(startCtrl.text);
  DateTime? get endDate =>
      endCtrl.text.isEmpty ? null : DateTime.tryParse(endCtrl.text);

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
  }
}

// ── Template Form Sheet ───────────────────────────────────────────────────────

class _TemplateFormSheet extends StatefulWidget {
  final TemplateModel? existing;
  final List<String> units;
  final List<String> currencies;

  const _TemplateFormSheet(
      {this.existing, required this.units, required this.currencies});

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  late final TextEditingController _bidCtrl;
  late final TextEditingController _capacityCtrl;

  String? _currency;
  String? _unit;
  bool _saving = false;

  final List<_MilestoneEntry> _milestones = [];

  List<AirportModel> _fromSuggestions = [];
  List<AirportModel> _toSuggestions = [];

  // Store the sheet's own scroll controller so we can scroll to bottom
  ScrollController? _sheetScrollCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.templateName ?? '');
    _startCtrl = TextEditingController(text: e?.startDateTime ?? '');
    _endCtrl = TextEditingController(text: e?.endDateTime ?? '');
    _fromCtrl = TextEditingController(text: e?.departureFrom ?? '');
    _toCtrl = TextEditingController(text: e?.arriveAt ?? '');
    _bidCtrl = TextEditingController(text: e?.bid ?? '');
    _capacityCtrl =
        TextEditingController(text: e?.courierCapacity ?? '');
    _currency = (e?.currency.isNotEmpty == true) ? e!.currency : null;
    _unit = (e?.unit.isNotEmpty == true) ? e!.unit : null;
    if (e != null) {
      for (final m in e.milestones) {
        _milestones.add(_MilestoneEntry.prefilled(
            m.title, m.description, m.startDateTime, m.endDateTime));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _bidCtrl.dispose();
    _capacityCtrl.dispose();
    for (final m in _milestones) {
      m.dispose();
    }
    super.dispose();
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  DateTime? get _templateStart => _startCtrl.text.isEmpty
      ? null
      : DateTime.tryParse(_startCtrl.text);
  DateTime? get _templateEnd => _endCtrl.text.isEmpty
      ? null
      : DateTime.tryParse(_endCtrl.text);

  /// Pick a date/time for a milestone field with proper constraints.
  Future<void> _pickMilestoneDateTime(
      TextEditingController ctrl, int milestoneIndex, bool isStart) async {
    final tStart = _templateStart;
    final tEnd = _templateEnd;

    // Floor: template start or previous milestone's end
    DateTime firstAllowed = tStart ?? DateTime(2020);
    if (isStart && milestoneIndex > 0) {
      final prevEnd = _milestones[milestoneIndex - 1].endDate;
      if (prevEnd != null &&
          prevEnd.isAfter(firstAllowed)) {
        firstAllowed = prevEnd;
      }
    }
    if (!isStart) {
      // End date must be after this milestone's start date
      final msStart = _milestones[milestoneIndex].startDate;
      if (msStart != null && msStart.isAfter(firstAllowed)) {
        firstAllowed = msStart;
      }
    }

    // Ceiling: template end
    final lastAllowed = tEnd ?? DateTime(2100);

    if (firstAllowed.isAfter(lastAllowed)) {
      _showError('No valid date range available. '
          'Check template and previous milestone dates.');
      return;
    }

    DateTime initial = firstAllowed;
    if (initial.isBefore(DateTime.now())) initial = DateTime.now();
    if (initial.isAfter(lastAllowed)) initial = lastAllowed;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;

    final picked = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    // Final guard: within template range
    if (tStart != null && picked.isBefore(tStart)) {
      _showError('Milestone date must be within the job date range.');
      return;
    }
    if (tEnd != null && picked.isAfter(tEnd)) {
      _showError('Milestone date must be within the job date range.');
      return;
    }

    ctrl.text = picked.toString();
    if (mounted) setState(() {});
  }

  Future<void> _pickTemplateDateTime(TextEditingController ctrl) async {
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    ctrl.text = DateTime(
            date.year, date.month, date.day, time.hour, time.minute)
        .toString();
    if (mounted) setState(() {});
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _addMilestone() {
    setState(() => _milestones.add(_MilestoneEntry()));
    // Scroll to bottom so new milestone is visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_sheetScrollCtrl?.hasClients == true) {
        _sheetScrollCtrl!.animateTo(
          _sheetScrollCtrl!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Airport search ──────────────────────────────────────────────────────────

  Future<void> _fetchFromAirports(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _fromSuggestions = []);
      return;
    }
    try {
      final list =
          await DatabaseOperation().fetchAirportsFromDatabase(query);
      if (mounted) setState(() => _fromSuggestions = list);
    } catch (_) {}
  }

  Future<void> _fetchToAirports(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _toSuggestions = []);
      return;
    }
    try {
      final list =
          await DatabaseOperation().fetchAirportsFromDatabase(query);
      if (mounted) setState(() => _toSuggestions = list);
    } catch (_) {}
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);

    final milestones = _milestones
        .map((m) => TemplateMilestone(
              title: m.titleCtrl.text.trim(),
              description: m.descCtrl.text.trim(),
              startDateTime: m.startCtrl.text.trim(),
              endDateTime: m.endCtrl.text.trim(),
            ))
        .where((m) => m.title.isNotEmpty)
        .toList();

    final t = TemplateModel(
      templateId: widget.existing?.templateId,
      templateName: _nameCtrl.text.trim(),
      startDateTime: _startCtrl.text.trim(),
      endDateTime: _endCtrl.text.trim(),
      departureFrom: _fromCtrl.text.trim().toUpperCase(),
      arriveAt: _toCtrl.text.trim().toUpperCase(),
      bid: _bidCtrl.text.trim(),
      currency: _currency ?? '',
      courierCapacity: _capacityCtrl.text.trim(),
      unit: _unit ?? '',
      userId: uid,
      milestones: milestones,
    );

    try {
      final col =
          FirebaseFirestore.instance.collection('broker_templates');
      if (widget.existing?.templateId != null) {
        await col.doc(widget.existing!.templateId).update(t.toMap());
      } else {
        await col.add(t.toMap());
      }
      if (mounted) Navigator.pop(context);
      Fluttertoast.showToast(
        msg: widget.existing == null
            ? 'Template saved!'
            : 'Template updated!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) {
        _sheetScrollCtrl = scrollCtrl; // capture for programmatic scroll
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Text(isEdit ? 'Edit Template' : 'New Template',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollCtrl, // MUST use sheet's controller
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      // Template Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Template Name *',
                            border: OutlineInputBorder()),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Job Start Date
                      TextFormField(
                        controller: _startCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Job Start Date & Time',
                          border: const OutlineInputBorder(),
                          suffixIcon: _startCtrl.text.isEmpty
                              ? const Icon(Icons.calendar_today)
                              : GestureDetector(
                                  onTap: () => setState(
                                      () => _startCtrl.clear()),
                                  child: const Icon(Icons.close,
                                      color: Colors.red)),
                        ),
                        onTap: () =>
                            _pickTemplateDateTime(_startCtrl),
                      ),
                      const SizedBox(height: 14),

                      // Job End Date
                      TextFormField(
                        controller: _endCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Job End Date & Time',
                          border: const OutlineInputBorder(),
                          suffixIcon: _endCtrl.text.isEmpty
                              ? const Icon(Icons.calendar_today)
                              : GestureDetector(
                                  onTap: () =>
                                      setState(() => _endCtrl.clear()),
                                  child: const Icon(Icons.close,
                                      color: Colors.red)),
                        ),
                        onTap: () => _pickTemplateDateTime(_endCtrl),
                      ),
                      const SizedBox(height: 14),

                      // From Airport
                      TextFormField(
                        controller: _fromCtrl,
                        decoration: const InputDecoration(
                          labelText: 'From Airport (IATA)',
                          border: OutlineInputBorder(),
                          suffixIcon:
                              Icon(Icons.flight_takeoff, size: 18),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z]')),
                          UpperCaseTextFormatter(),
                        ],
                        onChanged: _fetchFromAirports,
                      ),
                      if (_fromSuggestions.isNotEmpty)
                        _airportList(_fromSuggestions, _fromCtrl, true),
                      const SizedBox(height: 14),

                      // To Airport
                      TextFormField(
                        controller: _toCtrl,
                        decoration: const InputDecoration(
                          labelText: 'To Airport (IATA)',
                          border: OutlineInputBorder(),
                          suffixIcon:
                              Icon(Icons.flight_land, size: 18),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z]')),
                          UpperCaseTextFormatter(),
                        ],
                        onChanged: _fetchToAirports,
                      ),
                      if (_toSuggestions.isNotEmpty)
                        _airportList(_toSuggestions, _toCtrl, false),
                      const SizedBox(height: 14),

                      // Bid + Currency
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _bidCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Bid Amount',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _currency,
                              hint: const Text('Currency',
                                  overflow: TextOverflow.ellipsis),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                              ),
                              items: widget.currencies
                                  .map((c) => DropdownMenuItem(
                                      value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _currency = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Capacity + Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _capacityCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Courier Capacity',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _unit,
                              hint: const Text('Unit',
                                  overflow: TextOverflow.ellipsis),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                              ),
                              items: widget.units
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _unit = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Milestones header ─────────────────────────────
                      Row(children: [
                        const Icon(Icons.flag_outlined,
                            color: Palette.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        const Text('Milestones',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addMilestone,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add',
                              style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: Palette.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                      ]),
                      if (_milestones.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('No milestones added',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ),

                      // ── Milestone cards ───────────────────────────────
                      ..._milestones.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        return _buildMilestoneCard(i, m);
                      }),

                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : Text(
                                  isEdit
                                      ? 'Update Template'
                                      : 'Save Template',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMilestoneCard(int i, _MilestoneEntry m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Milestone ${i + 1}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Palette.primaryColor)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                m.dispose();
                _milestones.removeAt(i);
              }),
              child: const Icon(Icons.close, size: 18, color: Colors.red),
            ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: m.titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: m.descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          // Start date — constrained to [template start OR prev milestone end, template end]
          _msDateField(m.startCtrl, 'Start Date & Time', i, true),
          const SizedBox(height: 8),
          // End date — constrained to [this milestone start, template end]
          _msDateField(m.endCtrl, 'End Date & Time', i, false),
        ],
      ),
    );
  }

  Widget _msDateField(TextEditingController ctrl, String label,
      int msIndex, bool isStart) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: ctrl.text.isEmpty
            ? const Icon(Icons.calendar_today, size: 16)
            : GestureDetector(
                onTap: () => setState(() => ctrl.clear()),
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
      ),
      onTap: () => _pickMilestoneDateTime(ctrl, msIndex, isStart),
    );
  }

  Widget _airportList(List<AirportModel> suggestions,
      TextEditingController ctrl, bool isFrom) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length > 5 ? 5 : suggestions.length,
        itemBuilder: (_, i) {
          final airport = suggestions[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.local_airport,
                size: 16, color: Palette.primaryColor),
            title: Text(airport.name ?? '',
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(airport.iataCode ?? '',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
            onTap: () => setState(() {
              ctrl.text = airport.iataCode ?? airport.name ?? '';
              if (isFrom) {
                _fromSuggestions = [];
              } else {
                _toSuggestions = [];
              }
            }),
          );
        },
      ),
    );
  }
}
