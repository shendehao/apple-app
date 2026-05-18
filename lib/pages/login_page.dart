import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config.dart';
import 'main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _usernameFocus.dispose(); _passwordFocus.dispose();
    _animCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    final u = _usernameCtrl.text.trim();
    final p = _passwordCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) { setState(() => _error = '请输入账号和密码'); return; }
    setState(() { _isLoading = true; _error = null; });
    final ok = await _authService.login(AppConfig.defaultServerUrl, u, p);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => const MainShell()));
    } else {
      setState(() { _isLoading = false; _error = '账号或密码错误'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(children: [
                    const SizedBox(height: 40),

                    // Logo
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/logo.png', width: 72, height: 72, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.shield_lefthalf_fill, size: 36, color: Color(0xFF1C1C1E)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Whisper', style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E), letterSpacing: -0.3,
                      fontFamily: '.SF Pro Display',
                    )),
                    const SizedBox(height: 6),
                    const Text('卡密管理', style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93), letterSpacing: 0.5, fontFamily: '.SF Pro Text')),

                    const SizedBox(height: 48),

                    // Username
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 16),
                        const Icon(CupertinoIcons.person, size: 18, color: Color(0xFFAEAEB2)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          controller: _usernameCtrl, focusNode: _usernameFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
                          decoration: const InputDecoration(
                            hintText: '账号', hintStyle: TextStyle(color: Color(0xFFC7C7CC), fontSize: 16),
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                          ),
                        )),
                        const SizedBox(width: 16),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // Password
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 16),
                        const Icon(CupertinoIcons.lock, size: 18, color: Color(0xFFAEAEB2)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          controller: _passwordCtrl, focusNode: _passwordFocus,
                          obscureText: _obscure,
                          onSubmitted: (_) => _login(),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
                          decoration: const InputDecoration(
                            hintText: '密码', hintStyle: TextStyle(color: Color(0xFFC7C7CC), fontSize: 16),
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                          ),
                        )),
                        GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(_obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 18, color: const Color(0xFFC7C7CC)),
                          ),
                        ),
                      ]),
                    ),

                    // Error
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _error != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(_error!, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13)),
                          )
                        : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 28),

                    // Login button
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _isLoading ? const Color(0xFF1C1C1E).withOpacity(0.7) : const Color(0xFF1C1C1E),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isLoading ? null : _login,
                            child: Center(
                              child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('登录', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: '.SF Pro Display', letterSpacing: 0.5)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
