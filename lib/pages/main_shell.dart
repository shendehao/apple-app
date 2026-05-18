import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'card_list_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pages = const [DashboardPage(), CardListPage(), SettingsPage()];
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() { _glowController.dispose(); super.dispose(); }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _glowController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _LiquidGlassNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        glowController: _glowController,
        items: const [
          _NavItem(icon: CupertinoIcons.chart_bar, activeIcon: CupertinoIcons.chart_bar_fill, label: '概览'),
          _NavItem(icon: CupertinoIcons.creditcard, activeIcon: CupertinoIcons.creditcard_fill, label: '卡密'),
          _NavItem(icon: CupertinoIcons.gear_alt, activeIcon: CupertinoIcons.gear_alt_fill, label: '设置'),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AnimationController glowController;
  final List<_NavItem> items;

  const _LiquidGlassNavBar({required this.currentIndex, required this.onTap, required this.glowController, required this.items});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(48, 0, 48, bottomPadding + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AnimatedBuilder(
            animation: glowController,
            builder: (context, child) {
              final glow = CurvedAnimation(parent: glowController, curve: Curves.easeOut).value;
              return Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.78 + glow * 0.08),
                      Colors.white.withOpacity(0.62),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.5 + glow * 0.15), width: 0.8),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.06 + glow * 0.06), blurRadius: 20 + glow * 10, spreadRadius: -2, offset: const Offset(0, 4)),
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2)),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) => _GlassNavButton(item: items[i], isActive: i == currentIndex, onTap: () => onTap(i))),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _GlassNavButton({required this.item, required this.isActive, required this.onTap});
  @override
  State<_GlassNavButton> createState() => _GlassNavButtonState();
}

class _GlassNavButtonState extends State<_GlassNavButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;

  @override
  void initState() { super.initState(); _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150), lowerBound: 0.0, upperBound: 0.1); }
  @override
  void dispose() { _scaleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF007AFF);
    const inactive = Color(0xFF8E8E93);
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) { _scaleCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (_, child) => Transform.scale(scale: 1 - _scaleCtrl.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? active.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(widget.isActive ? widget.item.activeIcon : widget.item.icon, key: ValueKey(widget.isActive), size: 24, color: widget.isActive ? active : inactive),
            ),
            const SizedBox(height: 2),
            Text(widget.item.label, style: TextStyle(fontSize: 10, fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400, color: widget.isActive ? active : inactive)),
          ]),
        ),
      ),
    );
  }
}
