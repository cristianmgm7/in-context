import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Simplified main app shell - just returns the navigation shell for now
class MainAppShell {
  const MainAppShell._();

  static StatefulShellRoute create() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(
                body: Center(
                  child: Text('Home Screen'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


