import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import 'shell_navigation.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return Scaffold(body: navigationShell);
    }

    final tabs = ShellNavigation.tabsFor(authState.user);
    if (tabs.isEmpty) {
      return Scaffold(body: navigationShell);
    }

    final selectedDisplayIndex = ShellNavigation.displayIndexForBranch(
      tabs,
      navigationShell.currentIndex,
    );
    final safeSelectedIndex =
        selectedDisplayIndex >= 0 ? selectedDisplayIndex : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeSelectedIndex,
        onDestinationSelected: (displayIndex) {
          navigationShell.goBranch(
            tabs[displayIndex].branchIndex,
            initialLocation: tabs[displayIndex].branchIndex ==
                navigationShell.currentIndex,
          );
        },
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
