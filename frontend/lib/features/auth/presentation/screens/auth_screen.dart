import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/whoomz_wordmark.dart';
import '../../../../shared/widgets/whoosh_texture.dart';
import '../providers/auth_notifier.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});
  final String mode; // 'signup' | 'login'

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late String _mode;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _showPw = false;
  bool _rememberMe = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getBool('whoomz.rememberMe');
      if (saved != null && mounted) setState(() => _rememberMe = saved);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  bool get _isSignup => _mode == 'signup';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    bool ok;
    if (_isSignup) {
      ok = await notifier.signup(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );
    } else {
      ok = await notifier.login(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
        rememberMe: _rememberMe,
      );
    }
    if (ok && mounted) {
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          const WhooshTexture(opacity: 0.06),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink),
                        label: Text(
                          'Back',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink,
                          ),
                        ),
                      ),
                      const WhoomzWordmark(size: 20),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Text(
                            _isSignup ? 'Create your account' : 'Welcome back',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 30, fontWeight: FontWeight.w800,
                              color: AppColors.ink, letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSignup
                                ? 'No card. No commitment. Just a whoosh.'
                                : 'Pick up your streak where you left it.',
                            style: GoogleFonts.dmSans(
                              fontSize: 15, color: AppColors.inkWithOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Social buttons
                          Row(
                            children: [
                              Expanded(child: _socialBtn('Google', _googleIcon())),
                              const SizedBox(width: 10),
                              Expanded(child: _socialBtn('Apple', const Icon(Icons.apple, size: 18))),
                            ],
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.inkWithOpacity(0.1))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'or',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.5, color: AppColors.inkWithOpacity(0.55),
                                    letterSpacing: 1, fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: AppColors.inkWithOpacity(0.1))),
                            ],
                          ),
                          const SizedBox(height: 18),

                          if (_isSignup) ...[
                            _field(
                              label: 'Your name',
                              controller: _nameCtrl,
                              placeholder: 'Aanya',
                              autofocus: true,
                              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Tell us your name' : null,
                            ),
                            const SizedBox(height: 14),
                          ],

                          _field(
                            label: 'Email',
                            controller: _emailCtrl,
                            placeholder: 'you@email.com',
                            keyboardType: TextInputType.emailAddress,
                            autofocus: !_isSignup,
                            validator: (v) {
                              if (v == null || !v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _field(
                            label: 'Password',
                            controller: _pwCtrl,
                            placeholder: _isSignup ? 'Create a password' : 'Your password',
                            obscure: !_showPw,
                            suffix: TextButton(
                              onPressed: () => setState(() => _showPw = !_showPw),
                              child: Text(
                                _showPw ? 'Hide' : 'Show',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.accent,
                                ),
                              ),
                            ),
                            validator: (v) => (v?.length ?? 0) < 6 ? 'At least 6 characters' : null,
                          ),

                          if (!_isSignup) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                    activeColor: AppColors.accent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(color: AppColors.inkWithOpacity(0.3)),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Text(
                                    'Remember me',
                                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.inkWithOpacity(0.7)),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (authState.error != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                authState.error!,
                                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.coral),
                              ),
                            ),
                          ],

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky submit
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.cream, AppColors.cream.withValues(alpha: 0)],
                  stops: const [0.75, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authState.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.accentWithOpacity(0.75),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: authState.loading
                          ? Text('One sec…', style: GoogleFonts.bricolageGrotesque(fontSize: 16.5, fontWeight: FontWeight.w700))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isSignup ? 'Create account' : 'Log in',
                                  style: GoogleFonts.bricolageGrotesque(fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                                ),
                                const SizedBox(width: 9),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignup ? 'Already with us? ' : 'New to Whoomz? ',
                        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.inkWithOpacity(0.6)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _mode = _isSignup ? 'login' : 'signup';
                          _formKey.currentState?.reset();
                        }),
                        child: Text(
                          _isSignup ? 'Log in' : 'Sign up',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    bool autofocus = false,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.dmSans(color: AppColors.inkWithOpacity(0.35)),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.inkWithOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.inkWithOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _socialBtn(String label, Widget icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: icon,
      label: Text(label, style: GoogleFonts.bricolageGrotesque(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: AppColors.inkWithOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // Simplified G logo using arcs
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.4, 2.8, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.4, 1.4, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 3.8, 1.1, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 4.9, 1.4, true, paint);
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.6, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(c.dx, c.dy - r * 0.15, r, r * 0.3), paint);
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}
