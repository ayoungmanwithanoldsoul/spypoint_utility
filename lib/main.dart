import 'package:flutter/material.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpyPoint Utility',
      theme: appTheme(),  // Custom theme
      routes: appRoutes(), // App routes
      initialRoute: '/',   // Default to Home
      onGenerateRoute: onGenerateRoute,
    );
  }
}
