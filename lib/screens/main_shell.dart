import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/widgets/common_bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final showBottomNavBar = navigationShell.currentIndex < 3;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showBottomNavBar
          ? CommonBottomNavBar(navigationShell: navigationShell)
          : null,
    );
  }
}
