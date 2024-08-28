import 'package:flutter/material.dart';
import 'package:spypoint_utility/presentation/screens/home_screen.dart';
import 'package:spypoint_utility/presentation/screens/manage_sd_card_screen.dart';
import 'package:spypoint_utility/presentation/screens/firmware_update_screen.dart';
import 'package:spypoint_utility/presentation/screens/firmwares_screen.dart';
import 'package:spypoint_utility/presentation/screens/logs_screen.dart';
import 'package:spypoint_utility/presentation/screens/about_screen.dart';

Map<String, WidgetBuilder> appRoutes() {
  return {
    '/': (context) => const HomeScreen(),
    '/manage-sd-card': (context) => const ManageSdCardScreen(),
    '/firmware-update': (context) => const FirmwareUpdateScreen(),
    '/firmwares': (context) => const FirmwaresScreen(),
    '/logs': (context) => const LogsScreen(),
    '/about': (context) => const AboutScreen(),
  };
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  final routes = appRoutes();
  final WidgetBuilder? builder = routes[settings.name];

  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder!(context),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}