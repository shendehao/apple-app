import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  String _username = '';
  String _serverUrl = '';

  @override
  void initState() { super.initState(); _loadInfo(); }

  Future<void> _loadInfo() async {
    final username = await _authService.getUsername() ?? '';
    final serverUrl = ApiClient().serverUrl;
    if (mounted) setState(() { _username = username; _serverUrl = serverUrl; });
  }

  Future<void> _logout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), isDestructiveAction: true, child: const Text('退出')),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      if (mounted) Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('设置', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _tile(CupertinoIcons.person_circle_fill, const Color(0xFF007AFF), '当前账号', _username.isEmpty ? '-' : _username),
                const Divider(height: 1, indent: 56, color: Color(0xFFE5E5EA)),
                _tile(CupertinoIcons.globe, const Color(0xFF34C759), '服务器', _serverUrl),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: _tile(CupertinoIcons.info_circle_fill, const Color(0xFF8E8E93), '关于', 'Whisper iOS v1.0.0'),
            ),
            const SizedBox(height: 32),
            SizedBox(height: 50, child: CupertinoButton(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(12),
              onPressed: _logout,
              child: const Text('退出登录', style: TextStyle(fontWeight: FontWeight.w600)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, Color color, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E))),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
      ])),
    ]),
  );
}
