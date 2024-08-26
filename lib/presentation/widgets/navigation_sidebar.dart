import 'package:flutter/material.dart';

class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      minWidth: 200,
      selectedIndex: _getSelectedIndex(context),
      onDestinationSelected: (int index) {
        _onItemTapped(index, context);
      },
      labelType: NavigationRailLabelType.all,
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.update),
          label: Text('Firmware Update'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sd_card),
          label: Text('Manage SD Card'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.cloud_download),
          label: Text('Firmwares'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.list),
          label: Text('Logs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.info),
          label: Text('About'),
        ),
      ],
    );
  }

  int _getSelectedIndex(BuildContext context) {
    String route = ModalRoute.of(context)!.settings.name!;
    switch (route) {
      case '/firmware-update':
        return 1;
      case '/manage-sd-card':
        return 2;
      case '/firmwares':
        return 3;
      case '/logs':
        return 4;
      case '/about':
        return 5;
      default:
        return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/firmware-update');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/manage-sd-card');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/firmwares');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/logs');
        break;
      case 5:
        Navigator.pushReplacementNamed(context, '/about');
        break;
    }
  }
}
