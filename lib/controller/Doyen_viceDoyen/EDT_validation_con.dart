import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bda_project/controller/main_controllers/auth_controller.dart';

class EDTValidationController extends GetxController {
  // API Configuration - Render deployment
  final String baseUrl = 'https://bda-project2.onrender.com/api';
  
  // Observable state variables
  var selectedSession = 'Session 1 - 2025/2026'.obs;
  var currentAnnee = '2025-2026'.obs;
  var currentSemester = 'S1'.obs;
  var userId = 0.obs;

  // Loading states
  var isLoading = false.obs;
  var isApproving = false.obs;

  final List<String> sessions = [
    'Session 1 - 2025/2026',
    'Session 2 - 2024/2025',
    'Session 1 - 2024/2025',
  ];

  // Schedules approved by chef department (status = VALIDE_DEPARTEMENT)
  final pendingSchedules = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    fetchPendingSchedules();
  }

  void _loadUserData() {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      
      if (user != null) {
        userId.value = user.id;
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void changeSession(String session) {
    selectedSession.value = session;
    // Parse session to get annee and semester
    if (session.contains('2025/2026')) {
      currentAnnee.value = '2025-2026';
      currentSemester.value = 'S1';
    } else if (session.contains('2024/2025')) {
      currentAnnee.value = '2024-2025';
      currentSemester.value = session.contains('Session 2') ? 'S2' : 'S1';
    }
    fetchPendingSchedules();
  }

  Future<void> fetchPendingSchedules() async {
    try {
      isLoading.value = true;
      
      final response = await http.get(
        Uri.parse('$baseUrl/approvals/doyen?annee=${currentAnnee.value}&semester=${currentSemester.value}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['schedules'] != null) {
          pendingSchedules.clear();
          pendingSchedules.addAll((data['schedules'] as List).map((s) => Map<String, dynamic>.from(s)));
          
          print('✅ Loaded ${pendingSchedules.length} schedules pending Doyen approval');
        }
      } else {
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ERROR in fetchPendingSchedules: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch schedules: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveSchedule(int scheduleId) async {
    try {
      isApproving.value = true;
      
      print('🔍 APPROVING SCHEDULE');
      print('   Schedule ID: $scheduleId');
      print('   Doyen ID: ${userId.value}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/approvals/doyen/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'schedule_id': scheduleId,
          'doyen_id': userId.value,
          'action': 'APPROVE',
          'comment': 'Schedule approved by Doyen/Vice-Doyen',
        }),
      );
      
      print('🔍 Approval Response Status: ${response.statusCode}');
      print('🔍 Approval Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS') {
          Get.snackbar(
            'Success',
            'Schedule approved and published successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade50,
            colorText: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
          
          await Future.delayed(const Duration(seconds: 2));
          fetchPendingSchedules(); // Refresh list
        } else {
          throw Exception(data['message'] ?? 'Approval failed');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Approval failed');
      }
    } catch (e) {
      print('❌ ERROR in approveSchedule: $e');
      Get.snackbar(
        'Error',
        'Failed to approve schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    } finally {
      isApproving.value = false;
    }
  }

  Future<void> rejectSchedule(int scheduleId, String comment) async {
    try {
      isApproving.value = true;
      
      print('🔍 REJECTING SCHEDULE');
      print('   Schedule ID: $scheduleId');
      print('   Doyen ID: ${userId.value}');
      print('   Comment: $comment');
      
      final response = await http.post(
        Uri.parse('$baseUrl/approvals/doyen/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'schedule_id': scheduleId,
          'doyen_id': userId.value,
          'action': 'REJECT',
          'comment': comment,
        }),
      );
      
      print('🔍 Rejection Response Status: ${response.statusCode}');
      print('🔍 Rejection Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS') {
          Get.snackbar(
            'Schedule Rejected',
            'The schedule has been rejected and sent back to Chef de Département',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700,
            duration: const Duration(seconds: 4),
            icon: const Icon(Icons.cancel, color: Colors.red),
          );
          
          await Future.delayed(const Duration(seconds: 2));
          fetchPendingSchedules(); // Refresh list
        } else {
          throw Exception(data['message'] ?? 'Rejection failed');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Rejection failed');
      }
    } catch (e) {
      print('❌ ERROR in rejectSchedule: $e');
      Get.snackbar(
        'Error',
        'Failed to reject schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    } finally {
      isApproving.value = false;
    }
  }

  void showApprovalDialog(int scheduleId, String department, String formation) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Approve Schedule',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve the exam schedule for $department - $formation?',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will change status to PUBLIE and make the schedule visible to students and teachers.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          Obx(() => ElevatedButton(
                onPressed: isApproving.value
                    ? null
                    : () {
                        Get.back();
                        approveSchedule(scheduleId);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: isApproving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.white
                        ),
                      )
                    : Text('Approve', style: GoogleFonts.inter()),
              )),
        ],
      ),
    );
  }

  void showRejectionDialog(int scheduleId, String department, String formation) {
    final commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'Reject Schedule',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a comment explaining why you are rejecting the schedule for $department - $formation:',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your comment here...',
                hintStyle: GoogleFonts.inter(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will change status to GENERE and send back to Chef de Département with your comments.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          Obx(() => ElevatedButton(
                onPressed: isApproving.value
                    ? null
                    : () {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) {
                          Get.snackbar(
                            'Comment Required',
                            'Please provide a comment before rejecting',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade50,
                            colorText: Colors.red.shade700,
                          );
                        } else {
                          Get.back();
                          rejectSchedule(scheduleId, comment);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isApproving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.white
                        ),
                      )
                    : Text('Reject', style: GoogleFonts.inter()),
              )),
        ],
      ),
    );
  }
}