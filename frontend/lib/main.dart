import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/today/presentation/today_screen.dart';
import 'features/tweaks/tweaks_controller.dart';

void main() {
  runApp(const ProviderScope(child: WhoomzApp()));
}

class WhoomzApp extends ConsumerWidget {
  const WhoomzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(tweaksProvider).accent.color;
    return MaterialApp(
      title: 'Whoomz',
      debugShowCheckedModeBanner: false,
      theme: whoomzTheme(Brightness.light, accent: accent),
      darkTheme: whoomzTheme(Brightness.dark, accent: accent),
      home: const _Gate(),
    );
  }
}

class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => Scaffold(
        body: Center(
          child: Text(
            'Whoomz',
            style: WhoomzType.metric.copyWith(color: context.wz.ink),
          ),
        ),
      ),
      error: (_, _) => const AuthScreen(),
      data: (user) => user == null ? const AuthScreen() : const TodayScreen(),
    );
  }
}
