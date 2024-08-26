import 'package:flutter/material.dart';
import 'package:spypoint_utility/presentation/layouts/sidebar_layout.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      content: Scaffold(
        appBar: AppBar(
          title: const Text('Logs'),
        ),
        body: const Center(
          child: Text('Welcome to the SpyPoint Utility Logs Page'),
        ),
      ),
    );
  }
}
