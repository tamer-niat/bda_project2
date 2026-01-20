import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var isAuthenticated = false.obs;
  var currentUser = Rxn<User>();
  var errorMessage = ''.obs;

  // API base URL - Render deployment
  final String baseUrl = 'https://bda-project2.onrender.com/api';

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // ✅ DEBUG: Print RAW API response
      print('🔍 RAW API RESPONSE:');
      print(jsonEncode(data));
      print('🔍 USER DATA FROM API:');
      print(jsonEncode(data['user']));

      if (response.statusCode == 200 && data['success'] == true) {
        // Login successful
        currentUser.value = User.fromJson(data['user']);
        isAuthenticated.value = true;
        
        // ✅ DEBUG: Print parsed user data
        print('✅ Login successful - PARSED DATA:');
        print('   User ID: ${currentUser.value?.id}');
        print('   Role: ${currentUser.value?.role}');
        print('   Department ID: ${currentUser.value?.departmentId}');
        print('   Department: ${currentUser.value?.department}');
        
        // Save user data locally (optional - using GetStorage)
        // final box = GetStorage();
        // box.write('user', data['user']);
        
        return true;
      } else {
        // Login failed
        errorMessage.value = data['message'] ?? 'Connexion échouée';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Erreur de connexion au serveur: ${e.toString()}';
      print('Login error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout method
  void logout() {
    currentUser.value = null;
    isAuthenticated.value = false;
    errorMessage.value = '';
    
    // Clear stored data
    // final box = GetStorage();
    // box.remove('user');
  }

  // Check if user is logged in (for app startup)
  Future<void> checkAuthStatus() async {
    // final box = GetStorage();
    // final userData = box.read('user');
    // if (userData != null) {
    //   currentUser.value = User.fromJson(userData);
    //   isAuthenticated.value = true;
    // }
  }

  // Get user role
  String? getUserRole() {
    return currentUser.value?.role;
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return currentUser.value?.role == role;
  }

  // Get user full name
  String getUserFullName() {
    return currentUser.value?.fullName ?? 'User';
  }
}

// ✅ FIXED: User model with department fields
class User {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final int? departmentId;      // ✅ Added
  final String? department;     // ✅ Added
  final int? formationId;       // For students
  final String? formation;      // For students
  final int? groupeId;          // ✅ Added for students

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.departmentId,
    this.department,
    this.formationId,
    this.formation,
    this.groupeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'],
      role: json['role'],
      departmentId: json['department_id'],      // ✅ Added
      department: json['department'],           // ✅ Added
      formationId: json['formation_id'],
      formation: json['formation'],
      groupeId: json['groupe_id'],              // ✅ Added for students
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'department_id': departmentId,
      'department': department,
      'formation_id': formationId,
      'formation': formation,
      'groupe_id': groupeId,
    };
  }

  String get fullName => '$prenom $nom';
}