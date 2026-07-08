import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_error.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _creating = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    if (email.isEmpty || password.isEmpty || (_creating && name.isEmpty)) {
      setState(() => _error = 'Fill everything in first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (_creating) {
        await controller.signUp(name: name, email: email, password: password);
      } else {
        await controller.signIn(email: email, password: password);
      }
    } on DioException catch (e) {
      setState(() => _error = ApiError.fromDio(e).message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text('Whoomz', style: WhoomzType.metric.copyWith(color: wz.ink)),
              const SizedBox(height: 8),
              Text(
                'Conversation-first fitness.',
                style: WhoomzType.body.copyWith(color: wz.whisper),
              ),
              const Spacer(flex: 2),
              AnimatedSize(
                duration: Motion.settle,
                curve: Motion.spring,
                alignment: Alignment.topCenter,
                child: _creating
                    ? _Field(controller: _name, hint: 'Name')
                    : const SizedBox(width: double.infinity),
              ),
              _Field(
                controller: _email,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              _Field(controller: _password, hint: 'Password', obscure: true),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: Motion.quick,
                child: _error == null
                    ? const SizedBox(height: 24, width: double.infinity)
                    : SizedBox(
                        height: 24,
                        width: double.infinity,
                        child: Text(
                          _error!,
                          key: ValueKey(_error),
                          style: WhoomzType.body.copyWith(
                            fontSize: 14,
                            color: wz.whisper,
                          ),
                        ),
                      ),
              ),
              const Spacer(flex: 3),
              _PrimaryButton(
                label: _busy
                    ? '…'
                    : (_creating ? 'Create account' : 'Continue'),
                onTap: _busy ? null : _submit,
              ),
              SizedBox(
                height: 64,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _busy
                        ? null
                        : () => setState(() {
                            _creating = !_creating;
                            _error = null;
                          }),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _creating ? 'SIGN IN INSTEAD' : 'CREATE ACCOUNT',
                        style: WhoomzType.caps.copyWith(color: wz.whisper),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: wz.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: wz.hairline),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: WhoomzType.body.copyWith(color: wz.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: WhoomzType.body.copyWith(color: wz.faint),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: Motion.quick,
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.wz.accent,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: WhoomzType.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
