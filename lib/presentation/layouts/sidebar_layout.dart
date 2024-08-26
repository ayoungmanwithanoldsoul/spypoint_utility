import 'package:flutter/material.dart';
import '../widgets/navigation_sidebar.dart';

class SidebarLayout extends StatelessWidget {
  final Widget content;

  const SidebarLayout({required this.content, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const NavigationSidebar(),  // Sidebar on the left
        Expanded(
          child: content,  // Main content on the right
        ),
      ],
    );
  }
}
