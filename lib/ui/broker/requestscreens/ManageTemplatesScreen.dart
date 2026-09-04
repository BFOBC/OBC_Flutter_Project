import 'package:broker_flutter_pp/res/custom_colors.dart';
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
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteTemplate(String id) async {
    await FirebaseFirestore.instance
        .collection('broker_templates')
        .doc(id)
        .delete();
    Fluttertoast.showToast(
      msg: 'Template deleted',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
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
                child: CircularProgressIndicator(color: Palette.primaryColor));
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
                onDelete: () => _deleteTemplate(t.templateId!),
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Text(
                    template.templateName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text('$label: ',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _TemplateFormSheet extends StatefulWidget {
  final TemplateModel? existing;
  final List<String> units;
  final List<String> currencies;

  const _TemplateFormSheet({
    this.existing,
    required this.units,
    required this.currencies,
  });

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
    _capacityCtrl = TextEditingController(text: e?.courierCapacity ?? '');
    _currency = (e?.currency.isNotEmpty == true) ? e!.currency : null;
    _unit = (e?.unit.isNotEmpty == true) ? e!.unit : null;
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);

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

  Future<void> _pickDateTime(TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    ctrl.text = dt.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Edit Template' : 'New Template',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  children: [
                    _field(_nameCtrl, 'Template Name *',
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _dateField(_startCtrl, 'Start Date & Time'),
                    const SizedBox(height: 14),
                    _dateField(_endCtrl, 'End Date & Time'),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _fromCtrl,
                      decoration: const InputDecoration(
                        labelText: 'From Airport (IATA)',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]')),
                        UpperCaseTextFormatter(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _toCtrl,
                      decoration: const InputDecoration(
                        labelText: 'To Airport (IATA)',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]')),
                        UpperCaseTextFormatter(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _bidCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Bid Amount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _currency,
                            hint: const Text('Currency'),
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
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
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Courier Capacity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            hint: const Text('Unit'),
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            items: widget.units
                                .map((u) => DropdownMenuItem(
                                    value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) => setState(() => _unit = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primaryColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(isEdit ? 'Update Template' : 'Save Template',
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
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      );

  Widget _dateField(TextEditingController ctrl, String label) =>
      TextFormField(
        controller: ctrl,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _pickDateTime(ctrl),
      );
}
