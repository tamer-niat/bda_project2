import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bda_project/controller/main_controllers/auth_controller.dart';

class DepartmentValidationWorkflowController extends GetxController {
  // API Configuration - Render deployment
  final String baseUrl = 'https://bda-project2.onrender.com/api';
  
  // User Info (should be passed from login)
  var userId = 0.obs;
  var userRole = ''.obs;
  
  // Department Info
  var departmentId = 0.obs;
  var departmentName = ''.obs;
  
  // Academic Period
  var currentAnnee = '2025-2026'.obs;
  var currentSemester = 'S1'.obs;
  
  // Current Schedule
  var scheduleId = 0.obs;
  var scheduleStatus = 'GENERE'.obs;
  var validationStatus = 'pending'.obs;
  
  // Schedule Summary Data
  var totalExams = 0.obs;
  var totalStudents = 485.obs;
  var totalProfessors = 8.obs;
  var totalRooms = 12.obs;
  var examPeriod = 'Jan 15 - Feb 10'.obs;
  var totalConflicts = 0.obs;
  
  // Loading states
  var isLoading = false.obs;
  var isApproving = false.obs;
  
  // Exam Schedule Preview
  final examSchedule = <Map<String, dynamic>>[].obs;
  
  // Approval details
  var lastChefAction = ''.obs;
  var lastDoyenAction = ''.obs;
  var approvalHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    try {
      // ✅ FIX: Get user data from AuthController instead of Get.arguments
      // This ensures we get the correct department for the logged-in user
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      
      if (user != null) {
        userId.value = user.id;
        userRole.value = user.role;
        departmentId.value = user.departmentId ?? 0;
        departmentName.value = user.department ?? '';
        
        print('🔍 VALIDATION CONTROLLER - User data from AuthController:');
        print('   userId: ${userId.value}');
        print('   userRole: ${userRole.value}');
        print('   departmentId: ${departmentId.value}');
        print('   departmentName: ${departmentName.value}');
      } else {
        // Fallback: Try Get.arguments if AuthController doesn't have user
        print('⚠️ WARNING: No user in AuthController, trying Get.arguments');
        if (Get.arguments != null) {
          userId.value = Get.arguments['userId'] ?? 0;
          userRole.value = Get.arguments['role'] ?? 'Chef-departement';
          departmentId.value = Get.arguments['departmentId'] ?? 0;
          departmentName.value = Get.arguments['department'] ?? '';
        } else {
          print('❌ ERROR: No user data available!');
          Get.snackbar(
            'Error',
            'Unable to load user information. Please log in again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700,
          );
          return;
        }
      }
      
      // Validate that we have department ID (required for filtering)
      if (departmentId.value == 0) {
        print('❌ ERROR: Missing department ID!');
        Get.snackbar(
          'Error',
          'Department information is missing. Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }
      
      // If department name is missing, fetch it from the API
      if (departmentName.value.isEmpty && departmentId.value > 0) {
        _fetchDepartmentName();
      }
      
      fetchScheduleForApproval();
    } catch (e, stackTrace) {
      print('❌ EXCEPTION in validation controller onInit: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to initialize validation page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // ============================================
  // API METHODS
  // ============================================
  
  Future<void> _fetchDepartmentName() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/departements'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['departements'] != null) {
          final dept = data['departements'].firstWhere(
            (d) => d['id'] == departmentId.value,
            orElse: () => null,
          );
          if (dept != null) {
            departmentName.value = dept['nom'] ?? 'Department ${departmentId.value}';
            print('✅ Fetched department name: ${departmentName.value}');
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch department name: $e');
      // Use a fallback name
      departmentName.value = 'Department ${departmentId.value}';
    }
  }
  
  Future<void> fetchScheduleForApproval() async {
    try {
      isLoading.value = true;
      
      print('🔍 DEBUG - Fetching schedules for:');
      print('   userId: ${userId.value}');
      print('   departmentId: ${departmentId.value}');
      
      final url = '$baseUrl/approvals/chef/${userId.value}?annee=${currentAnnee.value}&semester=${currentSemester.value}';
      print('   API URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('🔍 DEBUG - API Response:');
        print('   Success: ${data['success']}');
        print('   Schedule count: ${data['schedules']?.length ?? 0}');
        
        if (data['success'] && data['schedules'] != null && data['schedules'].length > 0) {
          // ✅ FIX: The API already filters by department in sp_get_schedules_for_chef
          // But let's verify we got the right department
          
          // Print ALL schedules to debug
          print('🔍 DEBUG - All schedules returned:');
          for (var i = 0; i < data['schedules'].length; i++) {
            final sched = data['schedules'][i];
            print('   Schedule $i: ${sched['formation']} - Dept: ${sched['department']} (ID: ${sched['department_id']})');
          }
          
          final schedule = data['schedules'][0];
          
          print('🔍 DEBUG - Using first schedule:');
          print('   Schedule ID: ${schedule['schedule_id']}');
          print('   Formation: ${schedule['formation']}');
          print('   Department: ${schedule['department']}');
          print('   Department ID: ${schedule['department_id']}');
          
          // ✅ VERIFY: Check if this schedule is actually for our department
          if (schedule['department_id'] != null && 
              schedule['department_id'] != departmentId.value) {
            print('⚠️ WARNING: Schedule department mismatch!');
            print('   Expected department_id: ${departmentId.value}');
            print('   Got department_id: ${schedule['department_id']}');
            
            Get.snackbar(
              'Error',
              'No schedules found for your department (${departmentName.value})',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade50,
              colorText: Colors.red.shade700,
            );
            return;
          }
          
          scheduleId.value = schedule['schedule_id'];
          departmentName.value = schedule['department'] ?? departmentName.value;
          // ⚠️ DON'T set totalExams here - it includes ALL departments in the schedule
          // We'll calculate it from department-filtered exam data in fetchScheduleDetails()
          scheduleStatus.value = schedule['statut'] ?? 'GENERE';
          
          _updateValidationStatus(schedule['statut'] ?? 'GENERE');
          
          if (schedule['last_action'] != null) {
            lastChefAction.value = schedule['last_action'];
          }
          
          print('✅ Schedule loaded successfully:');
          print('   Schedule ID: ${scheduleId.value}');
          print('   Department: ${departmentName.value}');
          print('   Status: ${scheduleStatus.value}');
          
          await fetchScheduleDetails();
        } else {
          print('ℹ️ No schedules found');
          Get.snackbar(
            'Info',
            'No schedules pending approval for ${departmentName.value}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.shade50,
            colorText: Colors.blue.shade700,
          );
        }
      } else {
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ERROR in fetchScheduleForApproval: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  void _updateValidationStatus(String status) {
    switch (status) {
      case 'GENERE':
        validationStatus.value = 'pending';
        break;
      case 'VALIDE_DEPARTEMENT':
        validationStatus.value = 'approved';
        break;
      case 'BROUILLON':
        validationStatus.value = 'rejected';
        break;
      case 'PUBLIE':
        validationStatus.value = 'approved';
        break;
      default:
        validationStatus.value = 'pending';
    }
  }
  
  Future<void> fetchScheduleDetails() async {
    try {
      print('🔍 FETCHING SCHEDULE DETAILS');
      print('   Schedule ID: ${scheduleId.value}');
      print('   Department ID: ${departmentId.value}');
      
      // Get approval details
      final approvalResponse = await http.get(
        Uri.parse('$baseUrl/approvals/details/${scheduleId.value}'),
      );
      
      if (approvalResponse.statusCode == 200) {
        final approvalData = json.decode(approvalResponse.body);
        final schedule = approvalData['schedule'];
        final history = approvalData['approval_history'] as List;
        
        scheduleStatus.value = schedule['current_status'] ?? 'GENERE';
        // ⚠️ DON'T use schedule totals - they include ALL departments!
        // We'll calculate from department-filtered exam data instead
        
        approvalHistory.clear();
        approvalHistory.addAll(history.map((h) => Map<String, dynamic>.from(h)));
        
        _updateValidationStatus(schedule['current_status'] ?? 'GENERE');
        
        print('✅ Approval details loaded');
        print('   Status: ${scheduleStatus.value}');
      }
      
      // ✅ CRITICAL FIX: Use department-filtered endpoint
      print('🔍 Fetching exams for schedule_id: ${scheduleId.value}, department_id: ${departmentId.value}');
      
      // Get the filtered exam details
      final examResponse = await http.get(
        Uri.parse('$baseUrl/schedule/${scheduleId.value}/details/department/${departmentId.value}'),
      );
      
      print('🔍 Exam API Response Status: ${examResponse.statusCode}');
      
      if (examResponse.statusCode == 200) {
        final examData = json.decode(examResponse.body);
        
        print('🔍 Received exam data:');
        print('   Success: ${examData['success']}');
        print('   Count: ${examData['count']}');
        print('   Department ID: ${examData['department_id']}');
        print('   Schedule ID: ${examData['schedule_id']}');
        
        examSchedule.clear();
        
        if (examData['count'] == 0) {
          print('⚠️ WARNING: No exams found for this department!');
          print('   This could mean:');
          print('   1. Schedule generation did not run for this department');
          print('   2. All exams belong to formations in other departments');
          print('   3. The schedule_id is for a different department');
          
          // Reset KPIs to zero
          totalExams.value = 0;
          totalStudents.value = 0;
          totalRooms.value = 0;
          totalProfessors.value = 0;
          
          Get.snackbar(
            'No Exams',
            'No exams found for ${departmentName.value} department in this schedule',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade50,
            colorText: Colors.orange.shade700,
            duration: const Duration(seconds: 5),
          );
          
          return;
        }
        
        // ✅ FIX: Calculate KPIs from department-filtered exam data only
        Set<String> uniqueRooms = {};
        Set<String> uniqueSupervisors = {};
        int totalStudentCount = 0;
        Map<String, Map<String, dynamic>> examsByDate = {};
        
        for (var exam in examData['exams']) {
          print('✅ Processing exam:');
          print('   Matiere: ${exam['matiere']}');
          print('   Formation: ${exam['formation']}');
          print('   Department: ${exam['department']}');
          print('   Date: ${exam['date_exam']}');
          print('   Room: ${exam['salle']}');
          print('   Students: ${exam['student_count']}');
          
          // Count unique rooms (only if room name is not null/empty)
          if (exam['salle'] != null && exam['salle'].toString().trim().isNotEmpty && exam['salle'] != 'TBA') {
            uniqueRooms.add(exam['salle'].toString());
          }
          
          // Count unique supervisors (only if supervisor name is not null/empty)
          if (exam['surveillant'] != null && exam['surveillant'].toString().trim().isNotEmpty && exam['surveillant'] != 'TBA') {
            // Split by comma in case multiple supervisors
            final supervisors = exam['surveillant'].toString().split(',');
            for (var sup in supervisors) {
              if (sup.trim().isNotEmpty) {
                uniqueSupervisors.add(sup.trim());
              }
            }
          }
          
          // Accumulate student count
          totalStudentCount += ((exam['student_count'] ?? 0) as int);
          
          final dateTime = DateTime.parse(exam['date_exam']);
          final dateKey = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
          
          if (!examsByDate.containsKey(dateKey)) {
            examsByDate[dateKey] = {
              'day': dateTime.day.toString().padLeft(2, '0'),
              'month': _getMonthAbbr(dateTime.month),
              'module': exam['matiere'] ?? 'N/A',
              'time': exam['heure_debut'] ?? 'N/A',
              'room': exam['salle'] ?? 'TBA',
              'students': exam['student_count'] ?? 0,
              'supervisor': exam['surveillant'] ?? 'TBA',
              'formation': exam['formation'] ?? 'N/A',
            };
          } else {
            // If date already has an exam, accumulate student count
            examsByDate[dateKey]!['students'] = 
              (examsByDate[dateKey]!['students'] as int) + (exam['student_count'] ?? 0);
            
            // Append additional module info
            examsByDate[dateKey]!['module'] = 
              '${examsByDate[dateKey]!['module']}, ${exam['matiere']}';
          }
        }
        
        // ✅ FIX: Set KPIs from department-filtered data only
        totalExams.value = examData['count'] ?? 0;  // Use count from filtered endpoint
        totalStudents.value = totalStudentCount;
        totalRooms.value = uniqueRooms.length;
        totalProfessors.value = uniqueSupervisors.length;
        
        // Sort by date
        final sortedEntries = examsByDate.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        
        examSchedule.addAll(sortedEntries.map((e) => e.value));
        
        print('✅ Schedule details loaded successfully');
        print('   Total exams (department-filtered): ${totalExams.value}');
        print('   Total students: ${totalStudents.value}');
        print('   Total rooms (unique): ${totalRooms.value}');
        print('   Total professors (unique): ${totalProfessors.value}');
        print('   Exams displayed: ${examSchedule.length}');
      } else {
        print('❌ Failed to fetch exams: ${examResponse.statusCode}');
        print('   Response body: ${examResponse.body}');
        throw Exception('Failed to fetch exams: ${examResponse.statusCode}');
      }
      
      // Get conflicts
      await fetchConflicts();
      
    } catch (e) {
      print('❌ ERROR in fetchScheduleDetails: $e');
      Get.snackbar(
        'Error',
        'Failed to load schedule details: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
    }
  }
  
  Future<void> fetchConflicts() async {
    try {
      // ⚠️ NOTE: This endpoint returns ALL conflicts, not department-filtered
      // For now, we show all conflicts. If needed, we can add a department filter endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/conflicts?annee=${currentAnnee.value}&semester=${currentSemester.value}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // TODO: Filter conflicts by department_id if needed
        // For now, showing all conflicts (some may involve other departments)
        totalConflicts.value = data['count'] ?? 0;
        print('✅ Conflicts loaded: ${totalConflicts.value} (all departments)');
      }
    } catch (e) {
      print('Failed to fetch conflicts: $e');
    }
  }
  
  Future<int> fetchPendingCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/approvals/pending-count?user_id=${userId.value}&annee=${currentAnnee.value}&semester=${currentSemester.value}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['pending_count'] ?? 0;
      }
    } catch (e) {
      print('Failed to fetch pending count: $e');
    }
    return 0;
  }
  
  // ============================================
  // APPROVAL ACTIONS
  // ============================================
  
  Future<void> approveSchedule() async {
    try {
      isApproving.value = true;
      
      print('🔍 APPROVING SCHEDULE');
      print('   Schedule ID: ${scheduleId.value}');
      print('   Chef ID: ${userId.value}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/approvals/chef/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'schedule_id': scheduleId.value,
          'chef_id': userId.value,
          'action': 'APPROVE',
          'comment': 'Schedule approved by Chef de Département ${departmentName.value}',
        }),
      );
      
      print('🔍 Approval Response Status: ${response.statusCode}');
      print('🔍 Approval Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS') {
          scheduleStatus.value = data['new_status'];
          validationStatus.value = 'approved';
          lastChefAction.value = 'APPROVED';
          
          Get.snackbar(
            'Success',
            'Schedule approved and forwarded to Doyen',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade50,
            colorText: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
          
          await Future.delayed(const Duration(seconds: 2));
          fetchScheduleForApproval();
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
  
  Future<void> rejectSchedule(String comment) async {
    try {
      isApproving.value = true;
      
      print('🔍 REJECTING SCHEDULE');
      print('   Schedule ID: ${scheduleId.value}');
      print('   Chef ID: ${userId.value}');
      print('   Comment: $comment');
      
      final response = await http.post(
        Uri.parse('$baseUrl/approvals/chef/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'schedule_id': scheduleId.value,
          'chef_id': userId.value,
          'action': 'REJECT',
          'comment': comment,
        }),
      );
      
      print('🔍 Rejection Response Status: ${response.statusCode}');
      print('🔍 Rejection Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS') {
          scheduleStatus.value = data['new_status'];
          validationStatus.value = 'rejected';
          lastChefAction.value = 'REJECTED';
          
          Get.snackbar(
            'Schedule Rejected',
            'The schedule has been rejected and sent back to Admin examens with your comments',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700,
            duration: const Duration(seconds: 4),
            icon: const Icon(Icons.cancel, color: Colors.red),
          );
          
          await Future.delayed(const Duration(seconds: 2));
          fetchScheduleForApproval();
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
  
  // ============================================
  // UI DIALOGS
  // ============================================
  
  void showApprovalDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Approve Department Schedule',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve the exam schedule for ${departmentName.value}?',
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
                      'This will change status to VALIDE_DEPARTEMENT and forward to Doyen for final approval.',
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
                        approveSchedule();
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

  void showRejectionDialog() {
    final commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'Reject Department Schedule',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a comment explaining why you are rejecting the schedule:',
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
                      'This will change status to BROUILLON and send back to Admin examens with your comments.',
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
                          rejectSchedule(comment);
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

  void viewFullSchedule() {
    Get.snackbar(
      'Full Schedule',
      'Opening detailed schedule view...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  
  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  @override
  void onClose() {
    super.onClose();
  }
}