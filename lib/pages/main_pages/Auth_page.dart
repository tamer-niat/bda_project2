import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bda_project/controller/main_controllers/auth_controller.dart';
import 'package:bda_project/pages/main_pages/homepage.dart';

class AuthPage extends StatelessWidget {
  final RxBool isobscure = true.obs;
  final RxBool isSignUpMode = false.obs;
  
  // Text editing controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Get AuthController instance
  final AuthController authController = Get.put(AuthController());

  AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.heightOf(context);
    double w = MediaQuery.widthOf(context);
    
    return Scaffold(
      body: Center(
        child: Container(
          height: h * 0.96,
          width: w * 0.96,
          child: Card(
            color: Colors.white,
            elevation: 25,
            child: Row(
                children: [
                  Container(
                    height: h * 0.96,
                    width: w * 0.96 * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.all(h * 0.05),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month,
                                    color: Colors.indigo.shade700,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exam Scheduler',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade900,
                                      ),
                                    ),
                                    Text(
                                      'Academic Platform',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          Text(
                            'Sign In to Your Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome back! Please enter your credentials.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Error message display
                          Obx(() => authController.errorMessage.value.isNotEmpty
                              ? Container(
                                  margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authController.errorMessage.value,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox.shrink()),

                          Form(
                            child: Column(
                              children: [
                                // Email field
                                Container(
                                  margin: EdgeInsets.only(
                                    top: 8,
                                    right: 24,
                                    left: 24,
                                  ),
                                  child: TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      label: Text(
                                        'Email Address',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      hintText: 'example@univ.dz',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Colors.indigo.shade400,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.indigo.shade700,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),

                                // Password field
                                Container(
                                  margin: EdgeInsets.only(
                                    top: 16,
                                    right: 24,
                                    left: 24,
                                  ),
                                  child: Obx(
                                    () => TextFormField(
                                      controller: passwordController,
                                      obscureText: isobscure.value,
                                      decoration: InputDecoration(
                                        label: Text(
                                          'Password',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        hintText: '••••••••',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outlined,
                                          color: Colors.indigo.shade400,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            isobscure.value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () {
                                            isobscure.value = !isobscure.value;
                                          },
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.indigo.shade700,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Sign In Button
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 24),
                                  width: double.infinity,
                                  height: 50,
                                  child: Obx(() => ElevatedButton(
                                        onPressed: authController.isLoading.value
                                            ? null
                                            : () async {
                                                final email = emailController.text.trim();
                                                final password = passwordController.text;

                                                if (email.isEmpty || password.isEmpty) {
                                                  Get.snackbar(
                                                    'Error',
                                                    'Please enter email and password',
                                                    backgroundColor: Colors.red.shade100,
                                                    colorText: Colors.red.shade900,
                                                  );
                                                  return;
                                                }

                                                final success = await authController.login(email, password);
                                                
                                                if (success) {
                                                  Get.offAll(() => HomePage());
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo.shade700,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: authController.isLoading.value
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'SIGN IN',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      )),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side panel
                  Container(
                    height: h * 0.96,
                    width: w * 0.947 * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      color: Colors.indigo.shade700,
                    ),
                    child: Container(
                      margin: EdgeInsets.all(h * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Join Our Academic Community',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Access your personalized exam schedule, track your progress, and stay organized throughout the academic year.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildFeature(Icons.calendar_today, 'Smart Scheduling'),
                          SizedBox(height: 15),
                          _buildFeature(Icons.notifications_active, 'Exam Reminders'),
                          SizedBox(height: 15),
                          _buildFeature(Icons.analytics, 'Performance Tracking'),
                          SizedBox(height: 15),
                          _buildFeature(Icons.cloud_sync, 'Cloud Synchronization'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}