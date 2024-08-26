import 'package:flutter/material.dart';
import 'package:spypoint_utility/presentation/layouts/sidebar_layout.dart';

class FirmwaresScreen extends StatelessWidget {
  const FirmwaresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      content: Scaffold(
        appBar: AppBar(
          title: const Text('Firmwares'),
        ),
        body: const Center(
          child: Text('Welcome to the SpyPoint Utility Firmwares Page'),
        ),
      ),
    );
  }
}
