import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Milestoneinputform extends StatefulWidget {
  final int index;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const Milestoneinputform({
    super.key,
    required this.index,
    required this.titleController,
    required this.descriptionController,
    required this.startController,
    required this.endController,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<Milestoneinputform> createState() => _MilestoneinputformState();
}

class _MilestoneinputformState extends State<Milestoneinputform> {
  late String mileStoneNodeID;

  // Voice assistant — used for Title and Description fields only
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String? _activeField;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _activeField = null),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _activeField = null);
        }
      },
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _listenForField(String fieldId, TextEditingController controller) async {
    if (!_speechAvailable) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _activeField = null);
      return;
    }
    setState(() => _activeField = fieldId);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          controller.text = result.recognizedWords;
          setState(() => _activeField = null);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Widget _micButton(String fieldId, TextEditingController controller) {
    final isActive = _activeField == fieldId;
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isActive ? Icons.mic : Icons.mic_none,
          key: ValueKey(isActive),
          color: isActive ? Colors.red : Palette.primaryColor,
          size: 20,
        ),
      ),
      tooltip: isActive ? 'Tap to stop' : 'Tap to speak',
      onPressed: () => _listenForField(fieldId, controller),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestone #${widget.index}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 5),

                /// Title
                TextField(
                  controller: widget.titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        _micButton('title_${widget.index}', widget.titleController),
                    helperText: _activeField == 'title_${widget.index}'
                        ? 'Listening…'
                        : null,
                    helperStyle:
                        const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 5),

                /// Description
                TextField(
                  controller: widget.descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    suffixIcon: _micButton(
                        'desc_${widget.index}', widget.descriptionController),
                    helperText: _activeField == 'desc_${widget.index}'
                        ? 'Listening…'
                        : null,
                    helperStyle:
                        const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 5),

                /// Start Date
                TextField(
                  controller: widget.startController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Time and Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  onTap: () => _selectDateTime(context, widget.startController),
                ),
                const SizedBox(height: 5),

                /// End Date
                TextField(
                  controller: widget.endController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'End Time and Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  onTap: () => _selectDateTime(context, widget.endController),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          /// Delete icon button
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Milestone',
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Milestone?'),
        content:
            const Text('Are you sure you want to delete this milestone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
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
          pickedTime.minute,
        );
        controller.text = dt.toString();
      }
    }
  }
}
