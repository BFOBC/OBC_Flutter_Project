import 'dart:async';

import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/UpperCaseTextFormatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  final TextEditingController _submissionStartDateController = TextEditingController();
  final TextEditingController _submissionEndDateController = TextEditingController();
  final TextEditingController _submissionDepartureController = TextEditingController();
  final TextEditingController _submissionArrivalController = TextEditingController();
  final TextEditingController _submissionBidController = TextEditingController();
  final TextEditingController _submissionCourierController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  List<MilestoneFormData> milestoneForms = [];
  String emptyLegRequestID = "";
  late List<String> milestoneNodeID = [];

  List<AirportModel> fromAirportSuggestions = [];
  List<AirportModel> toAirportSuggestions = [];
  String? _selectedUnit;
  final List<String> _units = ['kg', 'g', 'lb', 'ton'];
  String? _selectedCurrency;

  // ── Guided voice form ─────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _voiceMode = false;
  bool _isSpeaking = false;
  bool _isListeningVoice = false;
  int _voiceStep = 0;

  static const List<String> _voiceQuestions = [
    'Please say the start date and time. For example: June 24, 2026, 6 PM.',
    'Please say the end date and time.',
    'Please say the 3-letter departure airport code. For example: D X B for Dubai.',
    'Please say the 3-letter arrival airport code.',
    'Please say the bid amount. Say a number.',
    'Please say the currency. Say U S D for US dollar, or Euro.',
    'Please say the courier capacity. Say a number up to 5000.',
    'Please say the unit. Say kilograms, grams, pounds, or tons.',
  ];

  static const List<String> _voiceFieldNames = [
    'Start date and time',
    'End date and time',
    'Departure airport',
    'Arrival airport',
    'Bid amount',
    'Currency',
    'Courier capacity',
    'Unit',
  ];
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _submissionStartDateController.text = widget.data!.startDateTime ?? '';
      _submissionEndDateController.text = widget.data!.endDateTime ?? '';
      _submissionDepartureController.text = widget.data!.departureFrom ?? '';
      _submissionArrivalController.text = widget.data!.arriveAt ?? '';
      _submissionCourierController.text = widget.data!.courierCapacity ?? '';
      _submissionBidController.text = widget.data!.bid ?? '';
    }
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([_initTts(), _initSpeech()]);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _startVoiceMode();
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() => _isListeningVoice = false);
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListeningVoice = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  // ── Voice flow ────────────────────────────────────────────────────────────
  void _startVoiceMode() {
    if (!_speechAvailable || !mounted) return;
    setState(() {
      _voiceMode = true;
      _voiceStep = 0;
    });
    _askVoiceStep(0);
  }

  void _stopVoiceMode() {
    _tts.stop();
    if (_speech.isListening) _speech.stop();
    if (mounted) {
      setState(() {
        _voiceMode = false;
        _isSpeaking = false;
        _isListeningVoice = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    if (!mounted || text.isEmpty) return;
    if (_speech.isListening) await _speech.stop();
    if (mounted) setState(() => _isSpeaking = true);

    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setCancelHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setErrorHandler((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await _tts.speak(text);

    final timeout = Duration(seconds: (text.split(' ').length ~/ 2) + 5);
    await completer.future.timeout(timeout, onTimeout: () {});
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _askVoiceStep(int step) async {
    if (!mounted || !_voiceMode) return;
    if (step >= _voiceQuestions.length) {
      await _speak('All done. Your form is complete. Please review and tap Request Job.');
      if (mounted) setState(() => _voiceStep = _voiceQuestions.length);
      return;
    }
    if (_speech.isListening) await _speech.stop();
    if (mounted) setState(() { _voiceStep = step; _isListeningVoice = false; });
    await _speak(_voiceQuestions[step]);
    if (mounted && _voiceMode) _listenForVoiceStep(step);
  }

  Future<void> _listenForVoiceStep(int step) async {
    if (!_speechAvailable || !mounted || !_voiceMode || _isSpeaking) return;
    if (mounted) setState(() => _isListeningVoice = true);

    bool gotResult = false;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && mounted && !gotResult) {
          gotResult = true;
          if (mounted) setState(() => _isListeningVoice = false);
          _onVoiceResult(step, result.recognizedWords.trim());
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );

    if (mounted) setState(() => _isListeningVoice = false);
    if (!gotResult && mounted && _voiceMode) {
      await _speak('Are you still there? Please try again.');
      if (mounted && _voiceMode) _listenForVoiceStep(step);
    }
  }

  void _onVoiceResult(int step, String text) async {
    if (!mounted || !_voiceMode) return;
    if (text.isEmpty) {
      await _speak('I did not hear you. Please try again.');
      if (mounted && _voiceMode) _askVoiceStep(step);
      return;
    }
    await _handleVoiceResult(step, text);
  }

  Future<void> _handleVoiceResult(int step, String text) async {
    if (!mounted || !_voiceMode) return;
    final lower = text.toLowerCase().trim();

    // Voice commands
    if (lower.contains('repeat') || lower == 'again' || lower.contains('say again')) {
      await _askVoiceStep(step);
      return;
    }
    if ((lower == 'go back' || lower == 'back' || lower == 'previous') && step > 0) {
      await _askVoiceStep(step - 1);
      return;
    }
    if (lower == 'skip' || lower.contains('skip this')) {
      await _speak('Skipping ${_voiceFieldNames[step]}.');
      if (mounted && _voiceMode) await _askVoiceStep(step + 1);
      return;
    }
    if (lower == 'stop' || lower.contains('stop voice') || lower == 'cancel') {
      _stopVoiceMode();
      return;
    }

    bool valid = false;
    switch (step) {
      case 0:
        final dt = _parseSpokenDateTime(text);
        if (dt != null) {
          if (mounted) setState(() => _submissionStartDateController.text = dt);
          valid = true;
        }
        break;
      case 1:
        final dt = _parseSpokenDateTime(text);
        if (dt != null) {
          if (mounted) setState(() => _submissionEndDateController.text = dt);
          valid = true;
        }
        break;
      case 2:
        final code = _extractAirportCode(text);
        if (code != null) {
          if (mounted) setState(() => _submissionDepartureController.text = code);
          valid = true;
        }
        break;
      case 3:
        final code = _extractAirportCode(text);
        if (code != null) {
          if (mounted) setState(() => _submissionArrivalController.text = code);
          valid = true;
        }
        break;
      case 4:
        final n = _extractNumber(text);
        if (n != null && n > 0) {
          if (mounted) setState(() => _submissionBidController.text = _fmtNum(n));
          valid = true;
        }
        break;
      case 5:
        final c = _extractCurrency(text);
        if (c != null) {
          if (mounted) setState(() => _selectedCurrency = c);
          valid = true;
        }
        break;
      case 6:
        final n = _extractNumber(text);
        if (n != null && n > 0 && n <= 5000) {
          if (mounted) setState(() => _submissionCourierController.text = _fmtNum(n));
          valid = true;
        }
        break;
      case 7:
        final u = _extractUnit(text);
        if (u != null) {
          if (mounted) setState(() => _selectedUnit = u);
          valid = true;
        }
        break;
    }

    const confirmations = [
      'Start date saved.',
      'End date saved.',
      'Departure airport saved.',
      'Arrival airport saved.',
      'Bid amount saved.',
      'Currency saved.',
      'Capacity saved.',
      'Unit saved.',
    ];

    if (valid) {
      await _speak(confirmations[step]);
      if (mounted && _voiceMode) await _askVoiceStep(step + 1);
    } else {
      await _speak('I did not understand. Please try again.');
      if (mounted && _voiceMode) _listenForVoiceStep(step);
    }
  }

  String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);

  String? _parseSpokenDateTime(String text) {
    final months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7,
      'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final lower = text.toLowerCase();
    int? month, day, year, hour = 0, minute = 0;
    final bool pm = lower.contains('pm');
    final bool am = lower.contains('am');
    for (final entry in months.entries) {
      if (lower.contains(entry.key)) { month = entry.value; break; }
    }
    final nums = RegExp(r'\d+').allMatches(lower).map((m) => int.parse(m.group(0)!)).toList();
    if (month != null) {
      for (final n in nums) {
        if (n >= 2000 && n <= 2100) { year = n; continue; }
        if (n >= 1 && n <= 31 && day == null) { day = n; continue; }
        if (n >= 0 && n <= 23 && hour == 0) { hour = n; continue; }
        if (n >= 0 && n <= 59 && minute == 0) { minute = n; }
      }
    } else if (nums.length >= 3) {
      day = nums[0]; month = nums[1]; year = nums[2];
      if (nums.length > 3) hour = nums[3];
      if (nums.length > 4) minute = nums[4];
    }
    if (pm && hour! < 12) hour = hour! + 12;
    if (am && hour == 12) hour = 0;
    if (year != null && month != null && day != null) {
      try { return DateTime(year!, month!, day!, hour ?? 0, minute ?? 0).toString(); } catch (_) {}
    }
    return null;
  }

  String? _extractAirportCode(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length >= 3) return letters.substring(0, 3).toUpperCase();
    return null;
  }

  double? _extractNumber(String text) {
    final match = RegExp(r'\d+\.?\d*').firstMatch(text);
    if (match != null) return double.tryParse(match.group(0)!);
    return null;
  }

  String? _extractCurrency(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('usd') || lower.contains('dollar')) return 'USD';
    if (lower.contains('eur') || lower.contains('euro')) return 'EUR';
    return null;
  }

  String? _extractUnit(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('kilogram') || lower.trim() == 'kg') return 'kg';
    if (lower.contains('gram') && !lower.contains('kilogram')) return 'g';
    if (lower.contains('pound') || lower.contains('lb')) return 'lb';
    if (lower.contains('ton')) return 'ton';
    return null;
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<AirportModel>> fetchAirportsFromDatabase(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      return await dbHelper.fetchAirportsFromDatabase(query);
    } catch (e) {
      print('Error _fetchAirports $e');
      return [];
    }
  }

  Future<void> _fetchFromAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() { fromAirportSuggestions = airports; });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() { fromAirportSuggestions = []; });
    }
  }

  Future<void> _fetchToAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() { toAirportSuggestions = airports; });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() { toAirportSuggestions = []; });
    }
  }

  void _addMilestoneForm() {
    setState(() { milestoneForms.add(MilestoneFormData()); });
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
      final nodeID = (index < milestoneNodeID.length) ? milestoneNodeID[index] : null;
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
      Fluttertoast.showToast(msg: "Please fill all fields correctly.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
      return false;
    }
    final bidValue = double.tryParse(_submissionBidController.text.trim());
    if (bidValue == null || bidValue <= 0) {
      Fluttertoast.showToast(msg: "Please enter a valid bid amount.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
      return false;
    }
    if (_selectedCurrency == null || _selectedCurrency!.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a currency.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
      return false;
    }
    final capacity = double.tryParse(_submissionCourierController.text.trim());
    if (capacity == null || capacity <= 0) {
      Fluttertoast.showToast(msg: "Please enter a valid courier capacity.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
      return false;
    }
    if (capacity > 5000) {
      Fluttertoast.showToast(msg: "Courier capacity cannot exceed 5000.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
      return false;
    }
    try {
      final start = DateTime.parse(_submissionStartDateController.text);
      final end = DateTime.parse(_submissionEndDateController.text);
      if (!start.isBefore(end)) {
        Fluttertoast.showToast(msg: "Start date must be before end date.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Invalid date format.", backgroundColor: Colors.red, textColor: Colors.white);
      return false;
    }
    if (milestoneForms.isEmpty) {
      Fluttertoast.showToast(msg: "At least one milestone is required.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tts.stop();
    if (_speech.isListening) _speech.stop();
    _submissionStartDateController.dispose();
    _submissionEndDateController.dispose();
    _submissionDepartureController.dispose();
    _submissionArrivalController.dispose();
    _submissionBidController.dispose();
    _submissionCourierController.dispose();
    for (var form in milestoneForms) { form.dispose(); }
    super.dispose();
  }

  // ── Voice banner widget ───────────────────────────────────────────────────
  Widget _buildVoiceBanner() {
    final completed = _voiceStep >= _voiceQuestions.length;

    if (!_voiceMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _speechAvailable ? _startVoiceMode : null,
            icon: const Icon(Icons.mic),
            label: Text(_speechAvailable ? 'Start Voice Form' : 'Microphone unavailable'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.primaryColor,
              side: const BorderSide(color: Palette.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    final Color indicatorColor = _isListeningVoice
        ? Colors.red
        : _isSpeaking
            ? Colors.orange
            : completed
                ? Colors.green
                : Palette.primaryColor;

    final String stepLabel = completed
        ? 'Form Complete!'
        : 'Step ${_voiceStep + 1} of ${_voiceQuestions.length}: ${_voiceFieldNames[_voiceStep]}';

    final String statusLabel = _isSpeaking
        ? 'Speaking...'
        : _isListeningVoice
            ? 'Listening... speak now'
            : completed
                ? 'All fields filled'
                : 'Processing...';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor, width: 1.5),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              key: ValueKey(_isListeningVoice ? 'mic' : _isSpeaking ? 'vol' : 'idle'),
              _isListeningVoice
                  ? Icons.mic
                  : _isSpeaking
                      ? Icons.volume_up
                      : completed
                          ? Icons.check_circle
                          : Icons.mic_none,
              color: indicatorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stepLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(statusLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (!completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      value: _voiceStep / _voiceQuestions.length,
                      backgroundColor: Colors.grey.shade200,
                      color: Palette.primaryColor,
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Stop voice mode',
            onPressed: _stopVoiceMode,
          ),
        ],
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTextField2(
    TextEditingController controller,
    String labelText, {
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    int fieldStep = -1;
    if (controller == _submissionDepartureController) fieldStep = 2;
    else if (controller == _submissionArrivalController) fieldStep = 3;
    final isVoiceActive = _voiceMode && _voiceStep == fieldStep;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        enabledBorder: isVoiceActive
            ? OutlineInputBorder(borderSide: BorderSide(color: Palette.primaryColor, width: 2))
            : null,
        filled: isVoiceActive,
        fillColor: isVoiceActive ? Palette.primaryColor.withOpacity(0.05) : null,
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (value == null || value.isEmpty) return '$labelText is required';
        return null;
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool readOnly) {
    int fieldStep = -1;
    if (controller == _submissionStartDateController) fieldStep = 0;
    else if (controller == _submissionEndDateController) fieldStep = 1;
    final isVoiceActive = _voiceMode && _voiceStep == fieldStep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: isVoiceActive
              ? OutlineInputBorder(borderSide: BorderSide(color: Palette.primaryColor, width: 2))
              : null,
          filled: isVoiceActive,
          fillColor: isVoiceActive ? Palette.primaryColor.withOpacity(0.05) : null,
          suffixIcon: readOnly
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.calendar_today), SizedBox(width: 8)],
                )
              : null,
        ),
        onTap: readOnly
            ? () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context, initialDate: DateTime.now(),
                  firstDate: DateTime(2020), lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
                        pickedTime.hour, pickedTime.minute);
                    controller.text = dt.toString();
                  }
                }
              }
            : null,
      ),
    );
  }

  Widget _buildBidField() {
    final isVoiceActive = _voiceMode && (_voiceStep == 4 || _voiceStep == 5);
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
              decoration: InputDecoration(
                labelText: 'Bid Amount',
                border: const OutlineInputBorder(),
                enabledBorder: (_voiceMode && _voiceStep == 4)
                    ? OutlineInputBorder(borderSide: BorderSide(color: Palette.primaryColor, width: 2))
                    : null,
                filled: _voiceMode && _voiceStep == 4,
                fillColor: (_voiceMode && _voiceStep == 4) ? Palette.primaryColor.withOpacity(0.05) : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                isExpanded: true,
                hint: const Text('Currency'),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  enabledBorder: (_voiceMode && _voiceStep == 5)
                      ? OutlineInputBorder(borderSide: BorderSide(color: Palette.primaryColor, width: 2))
                      : null,
                  filled: _voiceMode && _voiceStep == 5,
                  fillColor: (_voiceMode && _voiceStep == 5) ? Palette.primaryColor.withOpacity(0.05) : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) { setState(() { _selectedCurrency = value; }); },
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
              decoration: InputDecoration(
                labelText: 'Courier Capacity',
                border: const OutlineInputBorder(),
                enabledBorder: (_voiceMode && _voiceStep == 6)
                    ? OutlineInputBorder(borderSide: BorderSide(color: Palette.primaryColor, width: 2))
                    : null,
                filled: _voiceMode && _voiceStep == 6,
                fillColor: (_voiceMode && _voiceStep == 6) ? Palette.primaryColor.withOpacity(0.05) : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedUnit,
              hint: const Text('Unit'),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: (_voiceMode && _voiceStep == 7)
                    ? OutlineInputBorder(borderSide: BorderSide(color: Palette.primaryColor, width: 2))
                    : null,
                filled: _voiceMode && _voiceStep == 7,
                fillColor: (_voiceMode && _voiceStep == 7) ? Palette.primaryColor.withOpacity(0.05) : null,
              ),
              items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
              onChanged: (value) { setState(() { _selectedUnit = value; }); },
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
        title: const Text("Request New Job", style: TextStyle(color: Colors.white)),
        backgroundColor: Palette.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _voiceMode
          ? FloatingActionButton.small(
              onPressed: _stopVoiceMode,
              backgroundColor: Colors.red,
              tooltip: 'Stop voice mode',
              child: const Icon(Icons.mic_off, color: Colors.white),
            )
          : null,
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
                submissionStart = DateTime.parse(_submissionStartDateController.text);
                submissionEnd = DateTime.parse(_submissionEndDateController.text);
                if (submissionStart.isAfter(submissionEnd)) {
                  Fluttertoast.showToast(msg: "Submission start date must be before end date.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
                  allMilestonesValid = false;
                }
              } catch (e) {
                Fluttertoast.showToast(msg: "Invalid submission date format.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
                allMilestonesValid = false;
              }
              if (allMilestonesValid) {
                for (int i = 0; i < milestoneForms.length; i++) {
                  final form = milestoneForms[i];
                  final title = form.titleController.text.trim();
                  if (title.isEmpty || form.startController.text.isEmpty || form.endController.text.isEmpty) {
                    allMilestonesValid = false;
                    Fluttertoast.showToast(msg: "Please complete all milestone #${i + 1} fields.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
                    break;
                  }
                  try {
                    final ms = DateTime.parse(form.startController.text);
                    final me = DateTime.parse(form.endController.text);
                    if (ms.isBefore(submissionStart!) || me.isAfter(submissionEnd!)) {
                      allMilestonesValid = false;
                      Fluttertoast.showToast(msg: "Milestone #${i + 1} ($title) dates must be within submission range.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
                      break;
                    }
                  } catch (e) {
                    allMilestonesValid = false;
                    Fluttertoast.showToast(msg: "Invalid date format in milestone #${i + 1}.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
                    break;
                  }
                }
              }
              final finalCapacity = "${_submissionCourierController.text.trim()} ${_selectedUnit ?? ''}";
              final finalBid = "${_submissionBidController.text.trim()} ${_selectedCurrency ?? ''}";
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Palette.primaryColor),
                          SizedBox(height: 16),
                          Text('Sending request...', style: TextStyle(fontSize: 14, color: Palette.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
                try {
                  await sendEmptyLegRequest(context);
                } catch (e) {
                  if (context.mounted) Navigator.of(context).pop();
                  Fluttertoast.showToast(msg: 'Failed to send request. Please try again.');
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Palette.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Request Job',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            _buildVoiceBanner(),
            const SizedBox(height: 6),
            _buildTextField(_submissionStartDateController, 'Start Time And Date', true),
            _buildTextField(_submissionEndDateController, 'End Time And Date', true),
            _buildStyledField(
              child: _buildTextField2(
                _submissionDepartureController,
                'From Location',
                onChanged: (value) { if (value.length == 3) _fetchFromAirportData(value); },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            _buildSuggestionList(fromAirportSuggestions, _submissionDepartureController, isFrom: true),
            _buildStyledField(
              child: _buildTextField2(
                _submissionArrivalController,
                'To Location',
                onChanged: (value) { if (value.length == 3) _fetchToAirportData(value); },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            _buildSuggestionList(toAirportSuggestions, _submissionArrivalController, isFrom: false),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
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
                        if (form.titleController.text.isEmpty || form.startController.text.isEmpty || form.endController.text.isEmpty) {
                          Fluttertoast.showToast(msg: "Please complete all required fields for milestone #${i + 1}.", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.TOP);
                          return;
                        }
                        Fluttertoast.showToast(msg: "Milestone #${i + 1} saved.", backgroundColor: Colors.green, textColor: Colors.white, gravity: ToastGravity.TOP);
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

  Widget _buildSuggestionList(List<AirportModel> suggestions, TextEditingController controller, {required bool isFrom}) {
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
              if (isFrom) { widget.selectedFromAirport = airport; fromAirportSuggestions = []; }
              else { widget.selectedToAirport = airport; toAirportSuggestions = []; }
            });
          },
        );
      },
    );
  }

  Future<void> _saveMilestoneToFirebase(Milestone milestone) async {
    try {
      final ref = FirebaseFirestore.instance.collection('milestones').doc();
      milestone.milestoneNodeID = ref.id;
      milestone.milestoneStatus = "pending";
      milestoneNodeID.add(ref.id);
      milestone.milestoneStartDateTime = convertToUTCFromStandardFormat(milestone.milestoneStartDateTime.toString());
      milestone.milestoneEndDateTime = convertToUTCFromStandardFormat(milestone.milestoneEndDateTime.toString());
      await ref.set(milestone.toMap());
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving milestone: $e", backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  Future<void> deleteMilestoneByID(String milestoneID) async {
    try {
      await FirebaseFirestore.instance.collection('milestones').doc(milestoneID).delete();
    } catch (e) {
      print('Error deleting milestone: $e');
    }
  }

  Future<void> sendEmptyLegRequest(BuildContext context) async {
    Provider.of<RoleProvider>(context, listen: false).clearMilestoneNodeIDS();
    Provider.of<RoleProvider>(context, listen: false).clearTask();
    final firestoreService = FirestoreService(context);
    final finalCapacity = "${_submissionCourierController.text.trim()} ${_selectedUnit ?? ''}";
    final finalBid = "${_submissionBidController.text.trim()} ${_selectedCurrency ?? ''}";
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
    newRequest.startTimeDate = convertToUTCFromStandardFormat(newRequest.startTimeDate.toString());
    newRequest.endTimeDate = convertToUTCFromStandardFormat(newRequest.endTimeDate.toString());
    final currentUser = FirebaseAuth.instance.currentUser;
    final courierData = await NotificationService.getCourierNameAndTokenById(widget.courierKey);
    final brokerData = currentUser != null
        ? await NotificationService.getBrokerNameAndTokenById(currentUser.uid)
        : null;
    String? requestId;
    final courierToken = courierData?['token'] as String?;
    final tasks = <Future>[
      firestoreService.saveEmptyLegRequest(newRequest, milestoneNodeID).then((id) { requestId = id; }),
    ];
    if (courierToken != null && courierToken.isNotEmpty) {
      tasks.add(NotificationService.sendNotification(
        title: "New Request", toToken: courierToken, type: "broker_request",
        screen: "DrawerScreen", extraData: {"senderName": brokerData?['name']},
      ));
    }
    await Future.wait(tasks);
    Navigator.of(context).pop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.primaryColor.withOpacity(0.1)),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_rounded, color: Palette.primaryColor, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Request Sent!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.textPrimary)),
              const SizedBox(height: 8),
              const Text('Your job request has been sent successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Palette.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primaryColor, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () { Navigator.of(context).pop(); _navigateToDrawerPage(); },
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startController.dispose();
    endController.dispose();
  }
}
