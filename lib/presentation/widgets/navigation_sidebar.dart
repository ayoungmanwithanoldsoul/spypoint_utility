import 'package:flutter/material.dart';

/// A stateless widget that wraps the [NavigationSidebarSection] inside a [SizedBox].
class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(child: NavigationSidebarSection());
  }
}

/// A stateful widget that represents the navigation drawer section.
/// This widget manages the state of the selected index and updates the
/// navigation based on user interaction.
class NavigationSidebarSection extends StatefulWidget {
  const NavigationSidebarSection({super.key});

  @override
  State<NavigationSidebarSection> createState() =>
      _NavigationSidebarSectionState();
}

class _NavigationSidebarSectionState extends State<NavigationSidebarSection> {
  // The index of the currently selected item in the navigation drawer.
  int navDrawerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      // Callback for handling the selection of a destination.
      onDestinationSelected: (selectedIndex) {
        setState(() {
          // Update the selected index and navigate to the corresponding route.
          navDrawerIndex = selectedIndex;
        });
        _onItemTapped(selectedIndex, context);
      },
      selectedIndex: navDrawerIndex, // The currently selected index.
      children: <Widget>[
        // Header for the navigation drawer section.
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'Spypoint Utility',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // Create a list of navigation drawer destinations.
        ...destinations.map((destination) {
          return NavigationDrawerDestination(
            label: Text(destination.label),
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
          );
        }),
      ],
    );
  }

  /// Handles the navigation when a destination is tapped.
  /// It uses [Navigator.pushReplacementNamed] to navigate to the new route.
  void _onItemTapped(int selectedIndex, BuildContext context) {
    switch (selectedIndex) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/manage-sd-card');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/firmware-update');
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the selected index based on the current route.
    setState(() {
      navDrawerIndex = _getSelectedIndex(context);
    });
  }

  /// Returns the index of the currently selected destination based on the current route.
  int _getSelectedIndex(BuildContext context) {
    String route = ModalRoute.of(context)!.settings.name!;
    switch (route) {
      case '/manage-sd-card':
        return 1;
      case '/firmware-update':
        return 2;
      case '/firmwares':
        return 3;
      case '/logs':
        return 4;
      case '/about':
        return 5;
      default:
        return 0; // Default to "Home" if no route matches.
    }
  }
}

/// A class representing a navigation drawer destination.
/// Each destination has a label, an icon, and a selected icon.
class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label; // The label of the destination.
  final Widget icon; // The icon for the unselected state.
  final Widget selectedIcon; // The icon for the selected state.
}

// List of destinations for the navigation drawer.
// Each destination is represented by a [Destination] object.
const List<Destination> destinations = <Destination>[
  Destination("Home", Icon(Icons.home_outlined), Icon(Icons.home)),
  Destination("Manage SD", Icon(Icons.sd_card_outlined), Icon(Icons.sd_card)),
  Destination("Firmware Update", Icon(Icons.download_outlined), Icon(Icons.download)),
  Destination("Manage Firmware", Icon(Icons.cloud_download_outlined), Icon(Icons.cloud_download)),
  Destination("Logs", Icon(Icons.view_timeline_outlined), Icon(Icons.view_timeline)),
  Destination("About", Icon(Icons.info_outline), Icon(Icons.info))
];
