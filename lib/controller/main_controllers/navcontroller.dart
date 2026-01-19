import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;
  var selectedDepartment = 'Tous'.obs;
  var departments = <String>['Tous'].obs;
  var isLoadingDepartments = true.obs;

  // API base URL
  final String baseUrl = 'http://localhost:8000/api';
  // For Android emulator: 'http://10.0.2.2:8000/api'
  // For real device: 'http://YOUR_IP:8000/api'

  @override
  void onInit() {
    super.onInit();
    loadDepartments();
  }

  // Load departments from API
  Future<void> loadDepartments() async {
    try {
      isLoadingDepartments.value = true;

      final response = await http.get(
        Uri.parse('$baseUrl/departements'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Extract department names from API response
          List<String> deptNames = ['Tous']; // Start with 'Tous'
          for (var dept in data['departements']) {
            deptNames.add(dept['nom']); // Add department name
          }
          departments.value = deptNames;
        }
      }
    } catch (e) {
      print('Error loading departments: $e');
      // Keep default values if API fails
    } finally {
      isLoadingDepartments.value = false;
    }
  }

  void changePage(int index) {
    selectedIndex.value = index;
    Get.back(); // close Drawer
  }

  void changeDepartment(String department) {
    selectedDepartment.value = department;
  }
}