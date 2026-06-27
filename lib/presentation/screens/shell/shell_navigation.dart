import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';

class ShellTab {
  const ShellTab({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

abstract final class ShellNavigation {
  static const int moreBranchIndex = 5;

  static List<ShellTab> tabsFor(AppUser user) {
    final tabs = <ShellTab>[];

    void addTab({
      required int branchIndex,
      required AppModule module,
      required String label,
      required IconData icon,
      required IconData selectedIcon,
    }) {
      if (user.canView(module)) {
        tabs.add(
          ShellTab(
            branchIndex: branchIndex,
            label: label,
            icon: icon,
            selectedIcon: selectedIcon,
          ),
        );
      }
    }

    addTab(
      branchIndex: 0,
      module: AppModule.dashboard,
      label: AppStrings.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    );
    addTab(
      branchIndex: 1,
      module: AppModule.jobWork,
      label: AppStrings.jobWork,
      icon: Icons.content_cut_outlined,
      selectedIcon: Icons.content_cut,
    );
    addTab(
      branchIndex: 2,
      module: AppModule.customers,
      label: AppStrings.customers,
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    );
    addTab(
      branchIndex: 3,
      module: AppModule.sales,
      label: AppStrings.sales,
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
    );
    addTab(
      branchIndex: 4,
      module: AppModule.delivery,
      label: AppStrings.deliveries,
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
    );

    tabs.add(
      const ShellTab(
        branchIndex: moreBranchIndex,
        label: AppStrings.more,
        icon: Icons.more_horiz,
        selectedIcon: Icons.more_horiz,
      ),
    );

    return tabs;
  }

  static int displayIndexForBranch(
    List<ShellTab> tabs,
    int branchIndex,
  ) {
    return tabs.indexWhere((tab) => tab.branchIndex == branchIndex);
  }
}
