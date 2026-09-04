import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/models/TemplateModel.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/UpperCaseTextFormatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../data/notification/NotificationService.dart';
import 'milestoneinputform.dart';

class SubmissionScreen extends StatefulWidget {
  final Task? data;
  final String brokerKey;
  final String courierKey;
  final Function(Task task) onSave;
  AirportModel? selectedFromAirport;
  AirportModel? selectedToAirport;

  SubmissionScreen({
    super.key,
    this.data,
    required this.brokerKey,
    required this.courierKey,
    required this.onSave,
  });

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final TextEditingController _submissionStartDateController =
      TextEditingController();
  final TextEditingController _submissionEndDateController =
      TextEditingController();
  final TextEditingController _submissionDepartureController =
      TextEditingController();
  final TextEditingController _submissionArrivalController =
      TextEditingController();
  final TextEditingController _submissionBidController =
      TextEditingController();
  final TextEditingController _submissionCourierController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();
  List<MilestoneFormData> milestoneForms = [];
  String emptyLegRequestID = "";
  late List<String> milestoneNodeID = [];

  List<AirportModel> fromAirportSuggestions = [];
  List<AirportModel> toAirportSuggestions = [];
  String? _selectedUnit;
  final List<String> _units = ['kg', 'g', 'lb', 'ton'];
  String? _selectedCurrency;

  // ── Templates ─────────────────────────────────────────────────────────────
  List<TemplateModel> _templates = [];
  TemplateModel? _selectedTemplate;
  bool _loadingTemplates = false;
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _submissionStartDateController.text =
          widget.data!.startDateTime ?? '';
      _submissionEndDateController.text = widget.data!.endDateTime ?? '';
      _submissionDepartureController.text =
          widget.data!.departureFrom ?? '';
      _submissionArrivalController.text = widget.data!.arriveAt ?? '';
      _submissionCourierController.text =
          widget.data!.courierCapacity ?? '';
      _submissionBidController.text = widget.data!.bid ?? '';
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (mounted) setState(() => _loadingTemplates = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('broker_templates')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _templates = snap.docs
              .map((d) =>
                  TemplateModel.fromMap(d.id, d.data()))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingTemplates = false);
  }

  void _applyTemplate(TemplateModel? t) {
    if (t == null) {
      setState(() => _selectedTemplate = null);
      return;
    }
    setState(() {
      _selectedTemplate = t;
      _submissionStartDateController.text = t.startDateTime;
      _submissionEndDateController.text = t.endDateTime;
      _submissionDepartureController.text = t.departureFrom;
      _submissionArrivalController.text = t.arriveAt;
      _submissionBidController.text = t.bid;
      _selectedCurrency = t.currency.isEmpty ? null : t.currency;
      _submissionCourierController.text = t.courierCapacity;
      _selectedUnit = t.unit.isEmpty ? null : t.unit;
    });
    Fluttertoast.showToast(
      msg: 'Template "${t.templateName}" loaded',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  // ── Airport helpers ────────────────────────────────────────────────────────
  Future<List<AirportModel>> fetchAirportsFromDatabase(String query) async {
    try {
      return await DatabaseOperation().fetchAirportsFromDatabase(query);
    } catch (_) {
      return [];
    }
  }

  Future<void> _fetchFromAirportData(String query) async {
    if (query.isNotEmpty) {
      final airports = await fetchAirportsFromDatabase(query);
      if (mounted) setState(() => fromAirportSuggestions = airports);
    } else {
      if (mounted) setState(() => fromAirportSuggestions = []);
    }
  }

  Future<void> _fetchToAirportData(String query) async {
    if (query.isNotEmpty) {
      final airports = await fetchAirportsFromDatabase(query);
      if (mounted) setState(() => toAirportSuggestions = airports);
    } else {
      if (mounted) setState(() => toAirportSuggestions = []);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _addMilestoneForm() {
    setState(() => milestoneForms.add(MilestoneFormData()));
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeMilestoneForm(int index) {
    if (index < 0 || index >= milestoneForms.length) return;
    setState(() {
      final nodeID =
          (index < milestoneNodeID.length) ? milestoneNodeID[index] : null;
      milestoneForms.removeAt(index);
      if (index < milestoneNodeID.length) {
        milestoneNodeID.removeAt(index);
        if (nodeID != null) deleteMilestoneByID(nodeID);
      }
    });
  }

  bool validate() {
    if (_submissionStartDateController.text.isEmpty ||
        _submissionEndDateController.text.isEmpty ||
        _submissionDepartureController.text.isEmpty ||
        _submissionArrivalController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please fill all fields correctly.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP);
      return false;
    }
    final bidValue =
        double.tryParse(_submissionBidController.text.trim());
    if (bidValue == null || bidValue <= 0) {
      Fluttertoast.showToast(
          msg: "Please enter a valid bid amount.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP);
      return false;
    }
    if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please select a currency.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP);
      return false;
    }
    final capacity =
        double.tryParse(_submissionCourierController.text.trim());
    if (capacity == null || capacity <= 0) {
      Fluttertoast.showToast(
          msg: "Please enter a valid courier capacity.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP);
      return false;
    }
    if (capacity > 5000) {
      Fluttertoast.showToast(
          msg: "Courier capacity cannot exceed 5000.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP);
      return false;
    }
    try {
      final start =
          DateTime.parse(_submissionStartDateController.text);
      final end = DateTime.parse(_submissionEndDateController.text);
      if (!start.isBefore(end)) {
        Fluttertoast.showToast(
            msg: "Start date must be before end date.",
            backgroundColor: Colors.red,
            textColor: Colors.white,
            gravity: ToastGravity.TOP);
        return false;
      }
    } catch (_) {
      Fluttertoast.showToast(
          msg: "Invalid date format.",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return false;
    }
    if (milestoneForms.isEmpty) {
      Fluttertoast.showToast(
          msg: "At least one milestone is required.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _submissionStartDateController.dispose();
    _submissionEndDateController.dispose();
    _submissionDepartureController.dispose();
    _submissionArrivalController.dispose();
    _submissionBidController.dispose();
    _submissionCourierController.dispose();
    _scrollController.dispose();
    for (var form in milestoneForms) {
      form.dispose();
    }
    super.dispose();
  }

  // ── Template dropdown ─────────────────────────────────────────────────────
  Widget _buildTemplateDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Palette.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              color: Palette.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: _loadingTemplates
                ? const SizedBox(
                    height: 20,
                    child: LinearProgressIndicator(
                        color: Palette.primaryColor))
                : DropdownButtonHideUnderline(
                    child: DropdownButton<TemplateModel>(
                      value: _selectedTemplate,
                      isExpanded: true,
                      hint: const Text('Load from template',
                          style: TextStyle(fontSize: 14)),
                      items: [
                        const DropdownMenuItem<TemplateModel>(
                          value: null,
                          child: Text('— No template —',
                              style: TextStyle(fontSize: 14)),
                        ),
                        ..._templates.map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.templateName,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: _applyTemplate,
                    ),
                  ),
          ),
          if (_templates.isEmpty && !_loadingTemplates)
            TextButton(
              onPressed: _loadTemplates,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Refresh',
                  style: TextStyle(
                      fontSize: 12, color: Palette.primaryColor)),
            ),
        ],
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTextField(
      TextEditingController controller, String label, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: readOnly
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8)
                  ],
                )
              : null,
        ),
        onTap: readOnly
            ? () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    final dt = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute);
                    controller.text = dt.toString();
                  }
                }
              }
            : null,
      ),
    );
  }

  Widget _buildTextField2(
    TextEditingController controller,
    String labelText, {
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (value == null || value.isEmpty) return '$labelText is required';
        return null;
      },
    );
  }

  Widget _buildBidField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _submissionBidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bid Amount',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                isExpanded: true,
                hint: const Text('Currency'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'USD',
                      child: Text('USD (\$)',
                          overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'EUR',
                      child: Text('EUR (€)',
                          overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) =>
                    setState(() => _selectedCurrency = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _submissionCourierController,
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
              value: _selectedUnit,
              hint: const Text('Unit'),
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
              items: _units
                  .map((unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedUnit = value),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request New Job',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Palette.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextButton(
            onPressed: () async {
              if (!validate()) return;
              bool allMilestonesValid = true;
              DateTime? submissionStart;
              DateTime? submissionEnd;
              try {
                submissionStart = DateTime.parse(
                    _submissionStartDateController.text);
                submissionEnd =
                    DateTime.parse(_submissionEndDateController.text);
                if (submissionStart.isAfter(submissionEnd)) {
                  Fluttertoast.showToast(
                      msg:
                          "Submission start date must be before end date.",
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      gravity: ToastGravity.TOP);
                  allMilestonesValid = false;
                }
              } catch (_) {
                Fluttertoast.showToast(
                    msg: "Invalid submission date format.",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    gravity: ToastGravity.TOP);
                allMilestonesValid = false;
              }
              if (allMilestonesValid) {
                for (int i = 0; i < milestoneForms.length; i++) {
                  final form = milestoneForms[i];
                  final title = form.titleController.text.trim();
                  if (title.isEmpty ||
                      form.startController.text.isEmpty ||
                      form.endController.text.isEmpty) {
                    allMilestonesValid = false;
                    Fluttertoast.showToast(
                        msg:
                            "Please complete all milestone #${i + 1} fields.",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        gravity: ToastGravity.TOP);
                    break;
                  }
                  try {
                    final ms =
                        DateTime.parse(form.startController.text);
                    final me = DateTime.parse(form.endController.text);
                    if (ms.isBefore(submissionStart!) ||
                        me.isAfter(submissionEnd!)) {
                      allMilestonesValid = false;
                      Fluttertoast.showToast(
                          msg:
                              "Milestone #${i + 1} ($title) dates must be within submission range.",
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          gravity: ToastGravity.TOP);
                      break;
                    }
                  } catch (_) {
                    allMilestonesValid = false;
                    Fluttertoast.showToast(
                        msg:
                            "Invalid date format in milestone #${i + 1}.",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        gravity: ToastGravity.TOP);
                    break;
                  }
                }
              }
              final finalCapacity =
                  "${_submissionCourierController.text.trim()} ${_selectedUnit ?? ''}";
              final finalBid =
                  "${_submissionBidController.text.trim()} ${_selectedCurrency ?? ''}";
              if (allMilestonesValid) {
                final task = Task(
                  startDateTime: _submissionStartDateController.text,
                  endDateTime: _submissionEndDateController.text,
                  departureFrom: _submissionDepartureController.text,
                  arriveAt: _submissionArrivalController.text,
                  bid: finalBid,
                  courierCapacity: finalCapacity,
                );
                widget.onSave(task);
                for (int i = 0; i < milestoneForms.length; i++) {
                  final form = milestoneForms[i];
                  _saveMilestoneToFirebase(Milestone(
                    title: form.titleController.text,
                    description: form.descriptionController.text,
                    milestoneStartDateTime: form.startController.text,
                    milestoneEndDateTime: form.endController.text,
                    courierID: widget.courierKey,
                    milestoneNodeID: null,
                    brokerID: widget.brokerKey,
                    emptyLegRequestID: null,
                  ));
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Palette.primaryColor),
                          SizedBox(height: 16),
                          Text('Sending request...',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Palette.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
                try {
                  await sendEmptyLegRequest(context);
                } catch (_) {
                  if (context.mounted) Navigator.of(context).pop();
                  Fluttertoast.showToast(
                      msg: 'Failed to send request. Please try again.');
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Palette.primaryColor,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Request Job',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Submission Details',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            _buildTemplateDropdown(),
            _buildTextField(
                _submissionStartDateController, 'Start Time And Date', true),
            _buildTextField(
                _submissionEndDateController, 'End Time And Date', true),
            _buildStyledField(
              child: _buildTextField2(
                _submissionDepartureController,
                'From Location',
                onChanged: (value) {
                  if (value.length == 3) _fetchFromAirportData(value);
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            _buildSuggestionList(fromAirportSuggestions,
                _submissionDepartureController, isFrom: true),
            _buildStyledField(
              child: _buildTextField2(
                _submissionArrivalController,
                'To Location',
                onChanged: (value) {
                  if (value.length == 3) _fetchToAirportData(value);
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            _buildSuggestionList(toAirportSuggestions,
                _submissionArrivalController, isFrom: false),
            _buildBidField(),
            _buildCapacityField(),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addMilestoneForm,
                icon: const Icon(Icons.add),
                label: const Text("Add Milestone"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.1), end: Offset.zero)
                    .animate(animation),
                child:
                    FadeTransition(opacity: animation, child: child),
              ),
              child: Column(
                key: ValueKey(milestoneForms.length),
                children: milestoneForms.asMap().entries.map((entry) {
                  final i = entry.key;
                  final form = entry.value;
                  return KeyedSubtree(
                    key: ValueKey("milestone_$i"),
                    child: Milestoneinputform(
                      index: i + 1,
                      titleController: form.titleController,
                      descriptionController: form.descriptionController,
                      startController: form.startController,
                      endController: form.endController,
                      onSave: () {
                        if (form.titleController.text.isEmpty ||
                            form.startController.text.isEmpty ||
                            form.endController.text.isEmpty) {
                          Fluttertoast.showToast(
                              msg:
                                  "Please complete all required fields for milestone #${i + 1}.",
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              gravity: ToastGravity.TOP);
                          return;
                        }
                        Fluttertoast.showToast(
                            msg: "Milestone #${i + 1} saved.",
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            gravity: ToastGravity.TOP);
                      },
                      onDelete: () => _removeMilestoneForm(i),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionList(
    List<AirportModel> suggestions,
    TextEditingController controller, {
    required bool isFrom,
  }) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final airport = suggestions[index];
        return ListTile(
          title: Text(airport.name ?? 'Unknown'),
          onTap: () {
            setState(() {
              controller.text = airport.name ?? '';
              if (isFrom) {
                widget.selectedFromAirport = airport;
                fromAirportSuggestions = [];
              } else {
                widget.selectedToAirport = airport;
                toAirportSuggestions = [];
              }
            });
          },
        );
      },
    );
  }

  Future<void> _saveMilestoneToFirebase(Milestone milestone) async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('milestones').doc();
      milestone.milestoneNodeID = ref.id;
      milestone.milestoneStatus = "pending";
      milestoneNodeID.add(ref.id);
      milestone.milestoneStartDateTime = convertToUTCFromStandardFormat(
          milestone.milestoneStartDateTime.toString());
      milestone.milestoneEndDateTime = convertToUTCFromStandardFormat(
          milestone.milestoneEndDateTime.toString());
      await ref.set(milestone.toMap());
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error saving milestone: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> deleteMilestoneByID(String milestoneID) async {
    try {
      await FirebaseFirestore.instance
          .collection('milestones')
          .doc(milestoneID)
          .delete();
    } catch (_) {}
  }

  Future<void> sendEmptyLegRequest(BuildContext context) async {
    Provider.of<RoleProvider>(context, listen: false)
        .clearMilestoneNodeIDS();
    Provider.of<RoleProvider>(context, listen: false).clearTask();
    final firestoreService = FirestoreService(context);
    final finalCapacity =
        "${_submissionCourierController.text.trim()} ${_selectedUnit ?? ''}";
    final finalBid =
        "${_submissionBidController.text.trim()} ${_selectedCurrency ?? ''}";
    EmptyLegRequest newRequest = EmptyLegRequest(
      brokerID: widget.brokerKey,
      courierID: widget.courierKey,
      emptyLegRequestID: emptyLegRequestID,
      requestDateTime: DateTime.now().toIso8601String(),
      status: 'pending',
      milestoneNodeIDs: milestoneNodeID,
      startTimeDate: _submissionStartDateController.text,
      endTimeDate: _submissionEndDateController.text,
      departureLocation: _submissionDepartureController.text,
      arrivalLocation: _submissionArrivalController.text,
      bid: finalBid,
      isCourierRated: 'false',
      isBrokerRated: 'false',
      courierCapacity: finalCapacity,
    );
    newRequest.startTimeDate = convertToUTCFromStandardFormat(
        newRequest.startTimeDate.toString());
    newRequest.endTimeDate = convertToUTCFromStandardFormat(
        newRequest.endTimeDate.toString());

    final currentUser = FirebaseAuth.instance.currentUser;
    final courierData =
        await NotificationService.getCourierNameAndTokenById(
            widget.courierKey);
    final brokerData = currentUser != null
        ? await NotificationService.getBrokerNameAndTokenById(
            currentUser.uid)
        : null;

    String? requestId;
    final courierToken = courierData?['token'] as String?;
    final tasks = <Future>[
      firestoreService
          .saveEmptyLegRequest(newRequest, milestoneNodeID)
          .then((id) => requestId = id),
    ];
    if (courierToken != null && courierToken.isNotEmpty) {
      tasks.add(NotificationService.sendNotification(
        title: "New Request",
        toToken: courierToken,
        type: "broker_request",
        screen: "DrawerScreen",
        extraData: {"senderName": brokerData?['name']},
      ));
    }
    await Future.wait(tasks);
    Navigator.of(context).pop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.primaryColor.withOpacity(0.1)),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_rounded,
                    color: Palette.primaryColor, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Request Sent!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Palette.textPrimary)),
              const SizedBox(height: 8),
              const Text('Your job request has been sent successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Palette.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _navigateToDrawerPage();
                  },
                  child: const Text('OK',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 10), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _navigateToDrawerPage();
      }
    });
  }

  void _navigateToDrawerPage() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed('/DrawerScreen');
  }
}

Widget _buildStyledField({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
    child: child,
  );
}

class MilestoneFormData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startController.dispose();
    endController.dispose();
  }
}
