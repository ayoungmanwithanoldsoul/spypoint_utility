import 'package:flutter/material.dart';
import 'package:spypoint_utility/presentation/layouts/sidebar_layout.dart';

class FirmwareUpdateScreen extends StatelessWidget {
  const FirmwareUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      content: Scaffold(
        appBar: AppBar(
          title: const Text('Firmware Update'),
        ),
        body: const Center(
          child: Text('Welcome to the SpyPoint Utility Firmware Update Page'),
        ),
      ),
    );
  }
}
