import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../models/software.dart';
import '../services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = DashboardService();
  DashboardStats? _stats;
  List<SoftwareModel> _softwareList = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final stats = await _service.getStats();
    final software = await _service.getSoftwareList();
    if (mounted) setState(() { _stats = stats; _softwareList = software; _isLoading = false; });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : RefreshIndicator(
                color: const Color(0xFF007AFF),
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                          const SizedBox(height: 20),

                          if (_stats != null) ...[
                            // Top row - 2 big cards
                            Row(children: [
                              Expanded(child: _StatCard(title: '卡密总数', value: '${_stats!.totalCards}', color: const Color(0xFF007AFF), icon: CupertinoIcons.creditcard_fill)),
                              const SizedBox(width: 12),
                              Expanded(child: _StatCard(title: '未使用', value: '${_stats!.unusedCards}', color: const Color(0xFF34C759), icon: CupertinoIcons.checkmark_circle_fill)),
                            ]),
                            const SizedBox(height: 12),
                            // Middle row
                            Row(children: [
                              Expanded(child: _StatCard(title: '已使用', value: '${_stats!.usedCards}', color: const Color(0xFFFF9500), icon: CupertinoIcons.person_2_fill)),
                              const SizedBox(width: 12),
                              Expanded(child: _StatCard(title: '已封禁', value: '${_stats!.bannedCards}', color: const Color(0xFFFF3B30), icon: CupertinoIcons.nosign)),
                            ]),
                            const SizedBox(height: 12),
                            // Bottom row
                            Row(children: [
                              Expanded(child: _StatCard(title: '软件实例', value: '${_stats!.totalSoftware}', color: const Color(0xFF5856D6), icon: CupertinoIcons.cube_box_fill)),
                              const SizedBox(width: 12),
                              Expanded(child: _StatCard(title: '今日事件', value: '${_stats!.todayEvents}', color: const Color(0xFFAF52DE), icon: CupertinoIcons.bolt_fill)),
                            ]),
                          ],

                          if (_softwareList.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            const Text('软件实例', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(children: List.generate(_softwareList.length * 2 - 1, (i) {
                                if (i.isOdd) return const Divider(height: 1, indent: 56, color: Color(0xFFE5E5EA));
                                final sw = _softwareList[i ~/ 2];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(width: 36, height: 36,
                                    decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(CupertinoIcons.cube_box_fill, color: Color(0xFF007AFF), size: 18)),
                                  title: Text(sw.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                  subtitle: Text(sw.instanceId, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontFamily: 'Menlo')),
                                  trailing: Text('v${sw.version}', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                                );
                              })),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title; final String value; final Color color; final IconData icon;
  const _StatCard({required this.title, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    height: 100,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
      ]),
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}
