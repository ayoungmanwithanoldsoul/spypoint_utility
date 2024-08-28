import 'package:flutter/material.dart';
import 'package:spypoint_utility/presentation/layouts/sidebar_layout.dart';
import 'package:spypoint_utility/presentation/widgets/main_content.dart';

class ManageSdCardScreen extends StatelessWidget {
  const ManageSdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      content: Scaffold(
        appBar: AppBar(
          title: const Text('Manage SD card'),
        ),
        // body: const Center(
        //   child: Text('Welcome to the SpyPoint Utility Manage SD Card Page'),
        // ),
        body: const MainContent(),
      ),
    );
  }
}
