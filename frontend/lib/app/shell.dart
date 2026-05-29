import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../shared/widgets/bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [NavTab.home, NavTab.chat, NavTab.progress, NavTab.me];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: WhoomzBottomNav(
              active: _tabs[navigationShell.currentIndex],
              onTap: (tab) {
                final idx = _tabs.indexOf(tab);
                navigationShell.goBranch(
                  idx,
                  initialLocation: idx == navigationShell.currentIndex,
                );
              },
              hasUnread: _tabs[navigationShell.currentIndex] != NavTab.chat,
            ),
          ),
        ],
      ),
    );
  }
}
