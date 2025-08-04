import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/widgets/common_bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CommonBottomNavBar(
        navigationShell: navigationShell,
      ),
    );
  }
}
