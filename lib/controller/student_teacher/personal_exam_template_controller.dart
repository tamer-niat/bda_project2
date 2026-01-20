import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bda_project/controller/main_controllers/auth_controller.dart';

class PersonalExamTimetableController extends GetxController {
  // API Configuration - Render deployment
  final String baseUrl = 'https://bda-project2.onrender.com/api';
  
  // User Info
  var userName = 'Ahmed Benali'.obs;
  var userRole = 'Student'.obs; // or 'Teacher'
  var userId = 0.obs;
  var formationId = 0.obs;
  var groupeId = 0.obs;

  // Loading state
  var isLoading = false.obs;

  // View Mode
  var viewMode = 'list'.obs; // 'list' or 'calendar'

  // Filters
  var selectedSession = 'Session 1 - 2025/2026'.obs;
  var selectedStatus = 'All'.obs;
  
  // Academic period
  var currentAnnee = '2025-2026'.obs;
  var currentSemester = 'S1'.obs;

  final List<String> sessions = [
    'Session 1 - 2025/2026',
    'Session 2 - 2024/2025',
    'Session 1 - 2024/2025',
  ];

  final List<String> statusOptions = [
    'All',
    'Confirmed',
    'Pending',
    'Cancelled',
  ];

  // Calendar
  var focusedDay = DateTime.now().obs;
  var selectedDay = DateTime.now().obs;

  // Summary Data
  var totalExams = 8.obs;
  var nextExamDate = 'Jan 15'.obs;
  var totalDuration = 24.obs;
  var scheduleStatus = 'Confirmed'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    fetchExams();
  }
  
  void _loadUserData() {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      
      if (user != null) {
        userId.value = user.id;
        userRole.value = user.role ?? 'Student';
        userName.value = user.fullName;
        formationId.value = user.formationId ?? 0;
        groupeId.value = user.groupeId ?? 0;
        
        print('✅ User data loaded:');
        print('   User ID: ${userId.value}');
        print('   Role: ${userRole.value}');
        print('   Formation ID: ${formationId.value}');
        print('   Groupe ID: ${groupeId.value}');
        print('   Full Name: ${userName.value}');
      } else {
        print('⚠️ User is null in AuthController');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }
  
  Future<void> fetchExams() async {
    try {
      isLoading.value = true;
      
      print('🔍 Fetching exams for:');
      print('   User ID: ${userId.value}');
      print('   Role: ${userRole.value}');
      print('   Formation ID: ${formationId.value}');
      print('   Academic Year: ${currentAnnee.value}');
      print('   Semester: ${currentSemester.value}');
      
      // ✅ Fetch exams based on user role using specific endpoints
      http.Response response;
      
      if (userRole.value == 'Student' || userRole.value == 'Etudiant') {
        // For students: fetch exams for their formation
        if (userId.value == 0) {
          throw Exception('User ID is not set. Please log in again.');
        }
        
        final url = '$baseUrl/exams/student/${userId.value}?annee=${currentAnnee.value}&semester=${currentSemester.value}';
        print('   Student API URL: $url');
        
        response = await http.get(Uri.parse(url));
      } else if (userRole.value == 'Teacher' || userRole.value == 'Enseignant') {
        // For teachers: fetch exams where they are assigned
        if (userId.value == 0) {
          throw Exception('User ID is not set. Please log in again.');
        }
        
        final url = '$baseUrl/exams/teacher/${userId.value}?annee=${currentAnnee.value}&semester=${currentSemester.value}';
        print('   Teacher API URL: $url');
        
        response = await http.get(Uri.parse(url));
      } else {
        // Fallback to published exams
        response = await http.get(
          Uri.parse('$baseUrl/exams/published?annee=${currentAnnee.value}&semester=${currentSemester.value}'),
        );
      }
      
      print('   Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('   API Response:');
        print('     Success: ${data['success']}');
        print('     Count: ${data['count']}');
        
        if (data['success'] == true && data['exams'] != null) {
          List<dynamic> allExams = data['exams'];
          
          print('   Processing ${allExams.length} exams...');
          
          // Format exams based on user role
          if (userRole.value == 'Student' || userRole.value == 'Etudiant') {
            examsStudent.clear();
            print('   📝 Formatting ${allExams.length} exams for student...');
            
            for (var exam in allExams) {
              try {
                // ✅ The API already filters by formation_id, so we can trust the results
                // But we'll still verify for safety
                final examFormationId = exam['formation_id'];
                if (formationId.value == 0 || examFormationId == null || examFormationId == formationId.value) {
                  final formattedExam = _formatExamForStudent(exam);
                  examsStudent.add(formattedExam);
                  print('   ✅ Added exam: ${formattedExam['module']} on ${formattedExam['date']}');
                } else {
                  print('⚠️ Skipping exam - formation mismatch: exam_formation_id=$examFormationId, student_formation_id=${formationId.value}');
                }
              } catch (e) {
                print('❌ Error formatting exam: $e');
                print('   Exam data: $exam');
              }
            }
            
            totalExams.value = examsStudent.length;
            print('✅ Successfully loaded ${totalExams.value} exams for student (formation_id: ${formationId.value})');
            print('   Exams list length: ${examsStudent.length}');
            
            // Update summary if we have exams
            if (examsStudent.isNotEmpty) {
              final firstExam = examsStudent.first;
              final examDate = firstExam['date'] as DateTime;
              nextExamDate.value = '${_getMonthAbbr(examDate.month)} ${examDate.day}';
              
              // Calculate total duration
              totalDuration.value = examsStudent.fold(0, (sum, exam) => sum + (exam['duration'] as int? ?? 0));
            } else {
              print('⚠️ WARNING: examsStudent is empty after processing!');
            }
          } else if (userRole.value == 'Teacher' || userRole.value == 'Enseignant') {
            examsTeacher.clear();
            for (var exam in allExams) {
              examsTeacher.add(_formatExamForTeacher(exam));
            }
            totalExams.value = examsTeacher.length;
            print('✅ Loaded ${totalExams.value} exams for teacher');
            
            // Update summary if we have exams
            if (examsTeacher.isNotEmpty) {
              final firstExam = examsTeacher.first;
              final examDate = firstExam['date'] as DateTime;
              nextExamDate.value = '${_getMonthAbbr(examDate.month)} ${examDate.day}';
            }
          }
        } else {
          print('⚠️ No exams found or API returned success=false');
          print('   Response data: ${data.toString()}');
          if (userRole.value == 'Student' || userRole.value == 'Etudiant') {
            examsStudent.clear();
          } else {
            examsTeacher.clear();
          }
          totalExams.value = 0;
          
          // Show helpful message
          Get.snackbar(
            'No Exams Found',
            'No published exams found for your ${userRole.value == 'Student' || userRole.value == 'Etudiant' ? 'formation' : 'assignments'}. Exams will appear here once they are approved and published.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.shade50,
            colorText: Colors.blue.shade700,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        final errorBody = response.body;
        print('❌ API Error Response: $errorBody');
        
        // Clear exams on error
        if (userRole.value == 'Student' || userRole.value == 'Etudiant') {
          examsStudent.clear();
        } else {
          examsTeacher.clear();
        }
        totalExams.value = 0;
        
        throw Exception('Failed to fetch exams: ${response.statusCode} - $errorBody');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching exams: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load exams: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Map<String, dynamic> _formatExamForStudent(Map<String, dynamic> exam) {
    final dateTime = DateTime.parse(exam['date_exam']);
    final startTime = exam['heure_debut'] ?? '08:00';
    
    return {
      'day': dateTime.day.toString().padLeft(2, '0'),
      'month': _getMonthAbbr(dateTime.month),
      'date': dateTime,
      'module': exam['matiere'] ?? 'N/A',
      'time': startTime,
      'room': exam['salle'] ?? 'TBA',
      'duration': (exam['duree_minutes'] ?? 120) ~/ 60,
      'status': 'confirmed', // Published exams are confirmed
      'notes': '',
    };
  }
  
  Map<String, dynamic> _formatExamForTeacher(Map<String, dynamic> exam) {
    final dateTime = DateTime.parse(exam['date_exam']);
    final startTime = exam['heure_debut'] ?? '08:00';
    
    return {
      'day': dateTime.day.toString().padLeft(2, '0'),
      'month': _getMonthAbbr(dateTime.month),
      'date': dateTime,
      'module': exam['matiere'] ?? 'N/A',
      'time': startTime,
      'room': exam['salle'] ?? 'TBA',
      'duration': (exam['duree_minutes'] ?? 120) ~/ 60,
      'status': 'confirmed',
      'role': 'Supervisor', // Teacher is assigned to supervise this exam
      'notes': '',
    };
  }
  
  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  // Exam Data (For Students) - Now fetched from API (only PUBLIE exams)
  final examsStudent = <Map<String, dynamic>>[].obs;

  // Exam Data (For Teachers - with surveillance role) - Now fetched from API (only PUBLIE exams)
  final examsTeacher = <Map<String, dynamic>>[].obs;

  // Computed Properties
  List<Map<String, dynamic>> get currentExams {
    // ✅ Fix: Check for both 'Student' and 'Etudiant' roles
    return (userRole.value == 'Student' || userRole.value == 'Etudiant') 
        ? examsStudent 
        : examsTeacher;
  }

  List<Map<String, dynamic>> get filteredExams {
    // If no exams, return empty list
    if (currentExams.isEmpty) {
      return [];
    }
    
    return currentExams.where((exam) {
      bool statusMatch = selectedStatus.value == 'All' ||
          exam['status']?.toString().toLowerCase() ==
              selectedStatus.value.toLowerCase();
      return statusMatch;
    }).toList();
  }

  // Methods
  void changeViewMode(String mode) {
    viewMode.value = mode;
  }

  void changeSession(String session) {
    selectedSession.value = session;
    Get.snackbar(
      'Session Changed',
      'Viewing exams for $session',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void changeStatus(String status) {
    selectedStatus.value = status;
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    this.selectedDay.value = selectedDay;
    this.focusedDay.value = focusedDay;
  }

  List<Map<String, dynamic>> getExamsForDay(DateTime day) {
    return filteredExams.where((exam) {
      final examDate = exam['date'] as DateTime;
      return examDate.year == day.year &&
          examDate.month == day.month &&
          examDate.day == day.day;
    }).toList();
  }

  String getFormattedDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  void downloadTimetable() {
    Get.snackbar(
      'Downloading',
      'Preparing your exam timetable...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
    );

    Future.delayed(const Duration(seconds: 2), () {
      Get.snackbar(
        'Download Complete',
        'Your exam timetable has been downloaded as PDF',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade700,
      );
    });
  }

  void printTimetable() {
    Get.snackbar(
      'Print Preview',
      'Opening print preview...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // onInit is already defined above with fetchExams()

  @override
  void onClose() {
    super.onClose();
  }
}