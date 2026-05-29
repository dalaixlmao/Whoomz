import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/whoomz_wordmark.dart';
import '../../../../shared/widgets/whoosh_texture.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../../../shared/widgets/chat_bubble.dart';
import '../../../../shared/widgets/nutrition_stamp.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          const WhooshTexture(opacity: 0.06),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const WhoomzWordmark(size: 24),
                      TextButton(
                        onPressed: () => context.push('/auth?mode=login'),
                        child: Text(
                          'Log in',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentWithOpacity(0.10),
                            border: Border.all(color: AppColors.accentWithOpacity(0.22)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const WMark(size: 15, color: AppColors.accent),
                              const SizedBox(width: 7),
                              Text(
                                'Like texting a friend',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Headline
                        Text(
                          'Just tell us\nabout your day.',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -1.6,
                            height: 0.98,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'No forms. No spreadsheets. Chat your meals and moods — Whoomz does the rest in two seconds.',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkWithOpacity(0.62),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Chat proof card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.inkWithOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF281446).withValues(alpha: 0.18),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                                spreadRadius: -12,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AIBubble(
                                child: Text('Morning! How\'s your energy today? ☕'),
                              ),
                              const SizedBox(height: 10),
                              const UserBubble(text: 'Had chai + 2 theplas'),
                              const SizedBox(height: 10),
                              AIBubble(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Solid start 🙌', style: chatTextStyle()),
                                    const NutritionStamp(kcal: 420, proteinG: 14, carbsG: 55, fatG: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Value props
                        Row(
                          children: [
                            for (final v in [
                              ('2s', 'to log a meal'),
                              ('Voice', 'or text'),
                              ('No', 'shame, ever'),
                            ])
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: v.$1 == 'No' ? 0 : 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.inkWithOpacity(0.1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        v.$1,
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        v.$2,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11.5,
                                          color: AppColors.inkWithOpacity(0.62),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Social proof
                        Row(
                          children: [
                            ...[
                              const Color(0xFFFFB37A),
                              const Color(0xFFC9A2FF),
                              const Color(0xFF7ED9B0),
                              const Color(0xFFFF9E9E),
                            ].asMap().entries.map((e) => Transform.translate(
                              offset: Offset(e.key * -9.0, 0),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: e.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cream, width: 2.5),
                                ),
                                child: Center(
                                  child: Text(
                                    ['A', 'R', 'S', 'M'][e.key],
                                    style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '12,000+ ',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'checked in today',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      color: AppColors.inkWithOpacity(0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky bottom CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.cream, AppColors.cream.withValues(alpha: 0)],
                  stops: const [0.7, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/auth?mode=signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get started free',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/app/home'),
                    child: Text(
                      'Just show me the demo',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkWithOpacity(0.6),
                      ),
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
