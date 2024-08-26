import 'package:flutter/material.dart';
import 'package:spypoint_utility/presentation/layouts/sidebar_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      content: Scaffold(
        appBar: AppBar(
          title: const Text('About'),
        ),
        body: const Center(
          child: Text('Welcome to the SpyPoint Utility About Page'),
        ),
      ),
    );
  }
}
