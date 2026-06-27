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

    if (user.canView(AppModule.dashboard) ||
        user.canView(AppModule.expenses) ||
        user.canView(AppModule.plReport) ||
        user.canView(AppModule.team) ||
        user.canView(AppModule.rawMaterials) ||
        user.canView(AppModule.production) ||
        user.canView(AppModule.labour) ||
        user.canView(AppModule.equipment) ||
        user.canView(AppModule.qualityControl) ||
        user.canView(AppModule.delivery) ||
        user.canView(AppModule.suppliers) ||
        user.canView(AppModule.finishedGoods)) {
      tabs.add(
        const ShellTab(
          branchIndex: 4,
          label: AppStrings.more,
          icon: Icons.more_horiz,
          selectedIcon: Icons.more_horiz,
        ),
      );
    }

    return tabs;
  }

  static int displayIndexForBranch(
    List<ShellTab> tabs,
    int branchIndex,
  ) {
    return tabs.indexWhere((tab) => tab.branchIndex == branchIndex);
  }
}
