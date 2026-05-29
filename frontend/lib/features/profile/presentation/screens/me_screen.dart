import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/whoosh_texture.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../../../shared/widgets/streak_flame.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  static const _settings = [
    (icon: '🔔', label: 'Daily reminder', value: '8:30 PM'),
    (icon: '🎙️', label: 'Voice or text', value: 'Mix'),
    (icon: '🎯', label: 'Goal', value: 'Lose 4kg'),
    (icon: '🥘', label: 'Indian food first', value: 'On'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'You';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(name),
            _buildAppIcon(context),
            _buildSettingsList(),
            _buildLogout(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hey, $name',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: AppColors.ink, letterSpacing: -0.8,
            )),
          const SizedBox(height: 4),
          Row(
            children: [
              const StreakFlame(count: 7),
              const SizedBox(width: 8),
              Text('days of showing up. Quietly proud of you.',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14.5, fontWeight: FontWeight.w500,
                  color: AppColors.inkWithOpacity(0.55), letterSpacing: -0.1,
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: GestureDetector(
          onTap: () => context.go('/splash'),
          child: Column(
            children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: AppColors.accentWithOpacity(0.55), blurRadius: 36, offset: const Offset(0, 16)),
                    BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 0, offset: const Offset(0, 1)),
                  ],
                ),
                child: Stack(
                  children: [
                    const WhooshTexture(color: Colors.white, opacity: 0.1),
                    const Center(child: WMark(size: 72, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('APP ICON · TAP FOR SPLASH',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.inkWithOpacity(0.35), letterSpacing: 1.5,
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bubbleAI,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.inkWithOpacity(0.08)),
        ),
        child: Column(
          children: _settings.asMap().entries.map((e) {
            final s = e.value;
            final isLast = e.key == _settings.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(color: AppColors.inkWithOpacity(0.08)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentWithOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.label,
                        style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.1)),
                    ),
                    Text(s.value,
                      style: GoogleFonts.bricolageGrotesque(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: -0.1)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogout(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).logout();
            if (context.mounted) context.go('/');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.inkWithOpacity(0.15)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text('Log out',
            style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inkWithOpacity(0.6))),
        ),
      ),
    );
  }
}
