import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'dashboard_page.dart';
import 'card_list_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _pages = const [DashboardPage(), CardListPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    // iOS: 使用原生液态玻璃 CNTabBar (iOS 26+ 自动渲染原生效果, 旧版降级)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return Scaffold(
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: CNTabBar(
          items: [
            CNTabBarItem(
              label: '概览',
              icon: CNSymbol('chart.bar', size: 22),
              activeIcon: CNSymbol('chart.bar.fill', size: 22),
            ),
            CNTabBarItem(
              label: '卡密',
              icon: CNSymbol('creditcard', size: 22),
              activeIcon: CNSymbol('creditcard.fill', size: 22),
            ),
            CNTabBarItem(
              label: '设置',
              icon: CNSymbol('gearshape', size: 22),
              activeIcon: CNSymbol('gearshape.fill', size: 22),
            ),
          ],
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      );
    }

    // Web/Android: 自定义模拟液态玻璃导航栏
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _SimulatedGlassBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// 非iOS平台模拟液态玻璃导航栏
class _SimulatedGlassBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _SimulatedGlassBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(60, 0, 60, bottomPadding + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: const Color(0xFF1C1C1E).withOpacity(0.75),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => _TabBtn(
                icon: [CupertinoIcons.chart_bar, CupertinoIcons.creditcard, CupertinoIcons.gear_alt][i],
                activeIcon: [CupertinoIcons.chart_bar_fill, CupertinoIcons.creditcard_fill, CupertinoIcons.gear_alt_fill][i],
                label: ['概览', '卡密', '设置'][i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabBtn({required this.icon, required this.activeIcon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 64, height: 50,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isActive ? activeIcon : icon, size: 22, color: isActive ? const Color(0xFF0A84FF) : Colors.white.withOpacity(0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? const Color(0xFF0A84FF) : Colors.white.withOpacity(0.5))),
        ]),
      ),
    );
  }
}
