import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ExamSchedulingController extends GetxController {
  // API Base URL - UPDATE THIS TO MATCH YOUR BACKEND
  final String baseUrl = 'http://localhost:8000/api';
  
  // Observable state variables
  var selectedSession = 'Session 1 - 2025/2026'.obs;
  var selectedAnnee = '2025-2026'.obs;
  var selectedSemester = 'S1'.obs;
  
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var readinessScore = 0.obs;
  var totalExamsGenerated = 0.obs;
  var totalExamsTarget = 0.obs;
  var remainingConflicts = 0.obs;
  var pendingActions = 0.obs;
  
  // Auto-refresh timer
  Timer? _refreshTimer;
  
  final List<String> sessions = [
    'Session 1 - 2025/2026',
    'Session 2 - 2024/2025',
    'Session 1 - 2024/2025',
  ];

  // Conflict statistics
  var criticalConflicts = 0.obs;
  var mediumConflicts = 0.obs;
  var lowConflicts = 0.obs;

  // Conflict by type
  final conflictsByType = <Map<String, dynamic>>[].obs;

  // Department data
  final departments = <Map<String, dynamic>>[].obs;

  // Recent activity
  final recentActivities = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    print('🟢 ExamSchedulingController initialized');
    print('🌐 API Base URL: $baseUrl');
    print('📅 Selected Session: ${selectedAnnee.value} - ${selectedSemester.value}');
    
    // Initial data fetch
    fetchAllData();
    
    // Setup auto-refresh every 10 seconds
    startAutoRefresh();
  }

  @override
  void onClose() {
    // Cancel timer when controller is disposed
    stopAutoRefresh();
    super.onClose();
  }

  // Start auto-refresh timer
  void startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        print('⏰ Auto-refresh triggered');
        fetchAllData(silent: true); // Silent refresh without loading indicator
      },
    );
    print('✅ Auto-refresh enabled (every 10 seconds)');
  }

  // Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏸️ Auto-refresh stopped');
  }

  // Fetch all dashboard data
  Future<void> fetchAllData({bool silent = false}) async {
    if (!silent) {
      print('\n🔄 Starting to fetch all dashboard data...');
      isLoading.value = true;
    }
    
    errorMessage.value = '';
    
    try {
      // Test backend connectivity first (only on non-silent refresh)
      if (!silent) {
        final healthCheck = await testBackendConnection();
        if (!healthCheck) {
          errorMessage.value = 'Cannot connect to backend. Please ensure the server is running at $baseUrl';
          isLoading.value = false;
          return;
        }
      }

      await Future.wait([
        fetchDashboardStats(),
        fetchDepartmentStats(),
        fetchConflictsByType(),
        fetchRecentActivities(),
      ]);
      
      _calculateReadinessScore();
      
      if (!silent) {
        print('✅ All dashboard data fetched successfully!');
      }
    } catch (e) {
      print('❌ Error fetching dashboard data: $e');
      if (!silent) {
        errorMessage.value = 'Failed to fetch dashboard data: ${e.toString()}';
        Get.snackbar(
          'Error',
          'Failed to fetch dashboard data: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }

  // Test backend connection
  Future<bool> testBackendConnection() async {
    try {
      print('🔍 Testing backend connection...');
      final response = await http.get(
        Uri.parse('http://localhost:8000/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Backend is reachable');
        return true;
      } else {
        print('⚠️ Backend returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Cannot reach backend: $e');
      return false;
    }
  }

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    try {
      final url = '$baseUrl/dashboard/stats?annee=$selectedAnnee&semester=$selectedSemester';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final stats = data['stats'];
          totalExamsTarget.value = stats['total_exams_target'] ?? 0;
          totalExamsGenerated.value = stats['total_exams_generated'] ?? 0;
          remainingConflicts.value = stats['total_conflicts'] ?? 0;
          criticalConflicts.value = stats['critical_conflicts'] ?? 0;
          mediumConflicts.value = stats['medium_conflicts'] ?? 0;
          lowConflicts.value = stats['low_conflicts'] ?? 0;
          pendingActions.value = stats['pending_formations'] ?? 0;
        } else {
          throw Exception('API returned success=false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  // Fetch department statistics
  Future<void> fetchDepartmentStats() async {
    try {
      final url = '$baseUrl/dashboard/departments?annee=$selectedAnnee&semester=$selectedSemester';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final depts = data['departments'] as List;
          
          departments.value = depts.map((dept) => {
            'id': dept['department_id'],
            'name': dept['department_name'],
            'generated': dept['generated_exams'] ?? 0,
            'total': dept['total_exams'] ?? 0,
            'conflicts': dept['conflicts'] ?? 0,
            'status': dept['status'] ?? 'Pending',
            'completion_percentage': dept['completion_percentage'] ?? 0.0,
            'color': _getStatusColor(dept['status']),
          }).toList();
        } else {
          throw Exception('API returned success=false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching department stats: $e');
      rethrow;
    }
  }

  // Fetch conflicts by type
  Future<void> fetchConflictsByType() async {
    try {
      final url = '$baseUrl/dashboard/conflicts-by-type?annee=$selectedAnnee&semester=$selectedSemester';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final conflicts = data['conflicts'] as List;
          
          conflictsByType.value = conflicts.map((conflict) => {
            'name': conflict['conflict_name'],
            'count': conflict['count'],
          }).toList();
        } else {
          throw Exception('API returned success=false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching conflicts by type: $e');
      rethrow;
    }
  }

  // Fetch recent activities
  Future<void> fetchRecentActivities() async {
    try {
      final url = '$baseUrl/dashboard/recent-activities?annee=$selectedAnnee&semester=$selectedSemester&limit=10';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final activities = data['activities'] as List;
          
          recentActivities.value = activities.map((activity) => {
            'action': activity['action'],
            'department': activity['department'],
            'time': _formatTime(activity['time']),
            'icon': activity['icon'],
            'color': activity['color'],
          }).toList();
        } else {
          throw Exception('API returned success=false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching recent activities: $e');
      rethrow;
    }
  }

  // Helper method to get status color
  String _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return 'green';
      case 'In Progress':
        return 'orange';
      case 'Pending':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // Helper method to format time
  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'Unknown';
    
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return timeStr;
    }
  }

  // Calculate readiness score based on various factors
  void _calculateReadinessScore() {
    if (totalExamsTarget.value == 0) {
      readinessScore.value = 0;
      return;
    }
    
    final completionRate = (totalExamsGenerated.value / totalExamsTarget.value) * 100;
    final conflictScore = (1 - (remainingConflicts.value / (totalExamsTarget.value * 0.1))) * 100;
    final departmentScore = (departments.where((d) => d['status'] == 'Completed').length / 
                            (departments.length > 0 ? departments.length : 1)) * 100;
    
    readinessScore.value = ((completionRate * 0.4) + 
                           (conflictScore * 0.3) + 
                           (departmentScore * 0.3)).round().clamp(0, 100);
  }

  // Computed properties
  double get completionPercentage => 
    totalExamsTarget.value > 0 
      ? (totalExamsGenerated.value / totalExamsTarget.value) * 100 
      : 0;
  
  int get completedDepartments => 
    departments.where((d) => d['status'] == 'Completed').length;
  
  int get inProgressDepartments => 
    departments.where((d) => d['status'] == 'In Progress').length;
  
  bool get isReadyForValidation => 
    readinessScore.value >= 90 && remainingConflicts.value == 0;

  // Get conflict by specific type name
  int getConflictCountByType(String typeName) {
    final conflict = conflictsByType.firstWhereOrNull(
      (c) => c['name'] == typeName
    );
    return conflict?['count'] ?? 0;
  }

  // Methods
  void changeSession(String session) {
    selectedSession.value = session;
    
    // Parse session to get annee and semester
    final parts = session.split(' - ');
    if (parts.length == 2) {
      selectedAnnee.value = parts[1].replaceAll('/', '-');
      selectedSemester.value = parts[0].contains('1') ? 'S1' : 'S2';
      
      print('📅 Session changed to: ${selectedAnnee.value} - ${selectedSemester.value}');
      fetchAllData();
    }
  }

  // Refresh data manually
  Future<void> refreshData() async {
    print('🔄 Manual refresh triggered');
    await fetchAllData();
    if (errorMessage.value.isEmpty) {
      Get.snackbar(
        'Refreshed',
        'Dashboard data updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Force immediate refresh (call this after schedule generation)
  Future<void> forceRefresh() async {
    print('🔄 Force refresh triggered (after generation)');
    await fetchAllData();
  }
}