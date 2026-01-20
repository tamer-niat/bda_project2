import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class TimetableGenerationController extends GetxController {
  // Observable state
  var isGenerating = false.obs;
  var executionStatus = 'Ready'.obs;
  var progress = 0.0.obs;
  var currentStep = 0.obs;

  // Date selection
  var startDate = DateTime.now().add(const Duration(days: 7)).obs;
  var endDate = DateTime.now().add(const Duration(days: 35)).obs;

  // Semester selection
  var selectedSemester = 'S1'.obs;
  final availableSemesters = ['S1', 'S2'];

  // Time slots
  final timeSlots = <Map<String, dynamic>>[].obs;

  // Generation steps
  final generationSteps = [
    'Validating configuration',
    'Loading exam data',
    'Checking constraints',
    'Optimizing schedule',
    'Assigning rooms',
    'Finalizing timetable',
  ];

  // Results
  var lastGenerationResult = Rxn<Map<String, dynamic>>();

  // Auto-generate academic year
  String get academicYear {
    final now = DateTime.now();
    if (now.month <= 6) {
      return '${now.year - 1}-${now.year}';
    } else {
      return '${now.year}-${now.year + 1}';
    }
  }

  bool get canGenerate {
    if (timeSlots.isEmpty) return false;
    return timeSlots.where((slot) => slot['enabled'] as bool).isNotEmpty;
  }

  // Date selection methods
  void selectStartDate() async {
    final picked = await Get.dialog(
      DatePickerDialog(
        initialDate: startDate.value,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    if (picked != null) {
      startDate.value = picked;
      if (endDate.value.isBefore(picked)) {
        endDate.value = picked.add(const Duration(days: 28));
      }
    }
  }

  void selectEndDate() async {
    final picked = await Get.dialog(
      DatePickerDialog(
        initialDate: endDate.value,
        firstDate: startDate.value,
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    if (picked != null) {
      endDate.value = picked;
    }
  }

  // Time slot methods
  void toggleTimeSlot(int index) {
    timeSlots[index]['enabled'] = !(timeSlots[index]['enabled'] as bool);
    timeSlots.refresh();
  }

  void updateTimeSlot(int index, String label, String start, String end) {
    timeSlots[index] = {
      'label': label,
      'start': start,
      'end': end,
      'enabled': timeSlots[index]['enabled'],
    };
    timeSlots.refresh();
  }

  void addTimeSlot() {
    timeSlots.add({
      'label': 'New Slot ${timeSlots.length + 1}',
      'start': '08:00',
      'end': '10:00',
      'enabled': true,
    });
  }

  void removeTimeSlot(int index) {
    if (timeSlots.length > 1) {
      timeSlots.removeAt(index);
    } else {
      Get.snackbar(
        'Cannot Remove',
        'At least one time slot must remain',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Validation
  bool validateConfiguration() {
    if (timeSlots.isEmpty) {
      Get.snackbar('Error', 'Add at least one time slot');
      return false;
    }

    if (!timeSlots.any((slot) => slot['enabled'] as bool)) {
      Get.snackbar('Error', 'Enable at least one time slot');
      return false;
    }

    final days = endDate.value.difference(startDate.value).inDays;
    if (days < 14) {
      Get.snackbar('Error', 'Minimum 14 days required');
      return false;
    }

    return true;
  }

  // MAIN GENERATION - CONNECTED TO BACKEND
  Future<void> generateTimetable() async {
    if (!validateConfiguration()) return;

    isGenerating.value = true;
    executionStatus.value = 'Generating...';
    currentStep.value = 0;
    progress.value = 0.0;

    try {
      // Step progress simulation
      for (int i = 0; i < generationSteps.length; i++) {
        currentStep.value = i;
        progress.value = (i + 1) / generationSteps.length;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // CALL BACKEND
      await _callAPI();

      executionStatus.value = 'Success';
      Get.snackbar(
        'Success',
        'Schedule generated for $academicYear ${selectedSemester.value}',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade700,
      );
    } catch (e) {
      executionStatus.value = 'Failed';
      Get.snackbar(
        'Failed',
        e.toString(),
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    } finally {
      isGenerating.value = false;
    }
  }

  // BACKEND API CALL
  Future<void> _callAPI() async {
    // Use Render deployment URL
    final urls = ['https://bda-project2.onrender.com'];
    
    Exception? lastError;
    
    for (final baseUrl in urls) {
      try {
        final config = {
          'annee_universitaire': academicYear,
          'semester': selectedSemester.value,
          'start_date': startDate.value.toIso8601String().split('T')[0],
          'end_date': endDate.value.toIso8601String().split('T')[0],
          'time_slots': timeSlots
              .where((slot) => slot['enabled'] as bool)
              .map((slot) => {
                    'label': slot['label'],
                    'start': slot['start'],
                    'end': slot['end'],
                  })
              .toList(),
          'created_by': 3,
        };

        print('Trying $baseUrl...');
        print('Config: ${jsonEncode(config)}');

        final response = await http
            .post(
              Uri.parse('$baseUrl/api/generate-schedule'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(config),
            )
            .timeout(const Duration(seconds: 30));

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final result = data['result'];
            lastGenerationResult.value = {
              'examsScheduled': result['examsScheduled'] ?? 0,
              'formationsAffected': result['formationsAffected'] ?? 0,
              'daysUsed': result['daysUsed'] ?? 0,
              'totalConflicts': result['totalConflicts'] ?? 0,
              'studentConflicts': result['studentConflicts'] ?? 0,
              'teacherConflicts': result['teacherConflicts'] ?? 0,
              'roomConflicts': result['roomConflicts'] ?? 0,
            };
            return; // Success!
          } else {
            throw Exception(data['message'] ?? 'Generation failed');
          }
        } else if (response.statusCode == 404) {
          throw Exception(
              'Endpoint not found (404)\n'
              'The /api/generate-schedule endpoint does not exist.\n'
              'Make sure you are running the correct app.py file.');
        } else if (response.statusCode == 400) {
          final error = jsonDecode(response.body);
          throw Exception('Bad Request: ${error['detail'] ?? response.body}');
        } else if (response.statusCode == 500) {
          final error = jsonDecode(response.body);
          throw Exception('Server Error: ${error['detail'] ?? response.body}');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('Failed with $baseUrl: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        continue; // Try next URL
      }
    }
    
    // If we get here, all URLs failed
    throw Exception(
      'Could not connect to backend.\n'
      'Tried: ${urls.join(", ")}\n'
      '\n'
      'Steps to fix:\n'
      '1. Make sure Python backend is running: python app.py\n'
      '2. Check if it shows: "Uvicorn running on http://0.0.0.0:8000"\n'
      '3. Test in browser: http://localhost:8000/health\n'
      '\n'
      'Last error: ${lastError?.toString() ?? "Unknown"}');
  }

  // Configuration summary
  Map<String, dynamic> getConfigurationSummary() {
    return {
      'academicYear': academicYear,
      'semester': selectedSemester.value,
      'examPeriod': {
        'start': startDate.value,
        'end': endDate.value,
        'duration': endDate.value.difference(startDate.value).inDays,
      },
      'timeSlots': timeSlots.where((slot) => slot['enabled'] as bool).length,
    };
  }

  // Reset
  void resetConfiguration() {
    startDate.value = DateTime.now().add(const Duration(days: 7));
    endDate.value = DateTime.now().add(const Duration(days: 35));
    timeSlots.clear();
    selectedSemester.value = 'S1';
    Get.snackbar('Reset', 'Configuration reset to defaults');
  }

  // View conflicts dialog
  void viewConflicts() {
    if (lastGenerationResult.value == null) {
      Get.snackbar('No Data', 'Generate a schedule first');
      return;
    }

    final result = lastGenerationResult.value!;
    Get.dialog(
      AlertDialog(
        title: const Text('Conflicts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _conflictRow('Student', result['studentConflicts'], Colors.red),
            _conflictRow('Teacher', result['teacherConflicts'], Colors.orange),
            _conflictRow('Room', result['roomConflicts'], Colors.blue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _conflictRow(String label, dynamic count, Color color) {
    final intCount = (count is int) ? count : 0;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text('$intCount', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}