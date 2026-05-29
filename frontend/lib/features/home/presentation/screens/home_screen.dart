import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../../../shared/widgets/whoosh_texture.dart';
import '../../../../shared/widgets/w_stamp.dart';
import '../../../../shared/widgets/streak_flame.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'You';

    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context, greeting, name),
            _buildHeroCard(context),
            _buildYesterdaySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String greeting, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: AppColors.ink, letterSpacing: -0.7, height: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppColors.ink, letterSpacing: -0.7, height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),
          const WMark(size: 36, color: AppColors.accent, bgColor: Color(0x1A5C2D91)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 360),
        decoration: BoxDecoration(
          color: AppColors.heroCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.accentWithOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentWithOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            const WhooshTexture(color: AppColors.accent, opacity: 0.18),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S CHECK-IN",
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.accent, letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'How was your day so far?',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 34, fontWeight: FontWeight.w800,
                      color: AppColors.ink, letterSpacing: -1, height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tell me what you ate, how you moved, how you felt. Two seconds is enough.',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14.5, fontWeight: FontWeight.w500,
                      color: AppColors.inkWithOpacity(0.6), height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/app/chat'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentWithOpacity(0.55),
                                blurRadius: 18, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Chat with Whoomz',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: Colors.white, letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const StreakFlame(count: 7),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesterdaySection(BuildContext context) {
    final stats = [
      ('kcal', '1,720'),
      ('protein', '90g'),
      ('steps', '7.3k'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              'YESTERDAY',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.inkWithOpacity(0.4), letterSpacing: 1.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/app/summary'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.bubbleAI,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.inkWithOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sun · May 17',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.accent, letterSpacing: 1,
                        ),
                      ),
                      const WStamp(size: 36, color: AppColors.accent, rotateDegrees: -12),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accentWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.$1, style: GoogleFonts.bricolageGrotesque(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkWithOpacity(0.5))),
                          const SizedBox(width: 4),
                          Text(s.$2, style: GoogleFonts.bricolageGrotesque(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        ],
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '"Quiet Sunday. Read, walked, ate dal. Felt like a recovery day."',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14, color: AppColors.inkWithOpacity(0.67),
                      fontWeight: FontWeight.w500, height: 1.4, letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
