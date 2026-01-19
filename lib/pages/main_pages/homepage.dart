import 'package:bda_project/controller/main_controllers/auth_controller.dart';
import 'package:bda_project/controller/main_controllers/navcontroller.dart';
import 'package:bda_project/data/navItem.dart';
import 'package:bda_project/pages/Doyen_viceDouyen/EDT_validation.dart';
import 'package:bda_project/pages/chef_departement/validation_departement.dart';
import 'package:bda_project/pages/exam_admine/EDT_gen.dart';
import 'package:bda_project/pages/exam_admine/admin_examen_dashboard.dart';
import 'package:bda_project/pages/student_teacher/personal_exam_template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Get navigation items based on user role
  List<NavItem> _getNavItemsForRole(String? role) {
    if (role == 'Admin-examens') {
      return [
        NavItem(icon: Icons.dashboard, label: 'Exam Scheduling Dashboard', page: 0),
        NavItem(icon: Icons.auto_fix_high, label: 'Automatic Exam Timetable Generation', page: 1),
      ];
    } else if (role == 'Chef-departement') {
      return [
        NavItem(icon: Icons.check_circle, label: 'Department Validation Workflow', page: 0),
      ];
    } else if (role == 'Etudiant' || role == 'Enseignant') {
      return [
        NavItem(icon: Icons.calendar_month, label: 'Personal Exam Timetable', page: 0),
       
      ];
    } else {
      return [
        NavItem(icon: Icons.check_circle, label: 'EDT Validation', page: 0),
      ];
    }
  }

  // ✅ FIXED: Get pages based on user role with user data passed directly
  List<Widget> _getPagesForRole(String? role, AuthController authCtrl) {
    if (role == 'Admin-examens') {
      return [
        ExamSchedulingDashboard(),
        AutomaticTimetableGenerationPage(),
      ];
    } else if (role == 'Chef-departement') {
      // ✅ FIX: Pass user data directly to the validation page
      final user = authCtrl.currentUser.value;
      
      return [
        // ✅ Pass user data directly as a parameter or use Get.put with tag
        ValidationPageWrapper(
          userId: user?.id ?? 0,
          role: user?.role ?? '',
          departmentId: user?.departmentId ?? 0,
          department: user?.department ?? '',
        ),
      ];
    } else if (role == 'Etudiant' || role == 'Enseignant') {
      return [
        PersonalExamTimetable(),
      ];
    } else {
      return [
        
        EDTValidationPage()
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final NavigationController navCtrl = Get.put(NavigationController());
    final AuthController authCtrl = Get.find<AuthController>();

    return Obx(() {
      final userRole = authCtrl.currentUser.value?.role;
      final navItems = _getNavItemsForRole(userRole);
      final pages = _getPagesForRole(userRole, authCtrl);

      return Scaffold(
        drawer: Drawer(
          backgroundColor: const Color(0xFF1a237e),
          child: Column(
            children: [
              // ===== HEADER =====
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Plateforme EDT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authCtrl.currentUser.value?.role ?? 'User',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24),

              // ===== MENU =====
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isSelected = navCtrl.selectedIndex.value == index;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          item.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          navCtrl.changePage(index);
                        },
                      ),
                    );
                  },
                ),
              ),

              // ===== FOOTER =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        authCtrl.currentUser.value?.prenom[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authCtrl.currentUser.value?.fullName ?? 'User',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            authCtrl.currentUser.value?.role ?? 'Role',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: () {
                        authCtrl.logout();
                        Get.offAllNamed('/login');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Builder(
                      builder: (BuildContext builderContext) {
                        return IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                          onPressed: () {
                            Scaffold.of(builderContext).openDrawer();
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Obx(() => Text(
                          navItems[navCtrl.selectedIndex.value].label,
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            // Dynamic page content based on selected index
            Expanded(
              child: Obx(() => pages[navCtrl.selectedIndex.value]),
            ),
          ],
        ),
      );
    });
  }
}

// ✅ FIXED: Wrapper that provides user data through InheritedWidget or directly to child
class ValidationPageWrapper extends StatelessWidget {
  final int userId;
  final String role;
  final int departmentId;
  final String department;

  const ValidationPageWrapper({
    Key? key,
    required this.userId,
    required this.role,
    required this.departmentId,
    required this.department,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Option 1: If DepartmentValidationWorkflow accepts constructor parameters
    // return DepartmentValidationWorkflow(
    //   userId: userId,
    //   role: role,
    //   departmentId: departmentId,
    //   department: department,
    // );

    // Option 2: Store data in GetX controller with a tag
    // This makes the data accessible to the validation page's controller
    Get.put(
      UserDataController(
        userId: userId,
        role: role,
        departmentId: departmentId,
        department: department,
      ),
      tag: 'validation_user_data',
    );

    return DepartmentValidationWorkflow();
  }
}

// ✅ Simple controller to hold user data
class UserDataController extends GetxController {
  final int userId;
  final String role;
  final int departmentId;
  final String department;

  UserDataController({
    required this.userId,
    required this.role,
    required this.departmentId,
    required this.department,
  });
}