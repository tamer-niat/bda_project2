import 'package:bda_project/pages/main_pages/Auth_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(const Color.fromARGB(255, 58, 137, 255)), 
        ),
      ),
      debugShowCheckedModeBanner: false,
      home:  AuthPage(),
    );
  }
}
