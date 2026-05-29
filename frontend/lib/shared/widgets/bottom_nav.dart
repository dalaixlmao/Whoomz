import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum NavTab { home, chat, progress, me }

class WhoomzBottomNav extends StatelessWidget {
  const WhoomzBottomNav({
    super.key,
    required this.active,
    required this.onTap,
    this.accent = AppColors.accent,
    this.bgColor = AppColors.cream,
    this.textColor = AppColors.ink,
    this.hasUnread = false,
  });

  final NavTab active;
  final ValueChanged<NavTab> onTap;
  final Color accent;
  final Color bgColor;
  final Color textColor;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [bgColor, bgColor.withValues(alpha: 0)],
          stops: const [0.75, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(bottom: 22, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: NavTab.values.map((tab) => _NavItem(
          tab: tab,
          active: active == tab,
          accent: accent,
          textColor: textColor,
          hasUnread: tab == NavTab.chat && hasUnread,
          onTap: () => onTap(tab),
        )).toList(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.accent,
    required this.textColor,
    required this.hasUnread,
    required this.onTap,
  });

  final NavTab tab;
  final bool active;
  final Color accent;
  final Color textColor;
  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : textColor.withValues(alpha: 0.53);
    final label = switch (tab) {
      NavTab.home => 'Home',
      NavTab.chat => 'Chat',
      NavTab.progress => 'Progress',
      NavTab.me => 'Me',
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _TabIcon(tab: tab, active: active, color: color),
                if (hasUnread)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cream, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.tab, required this.active, required this.color});
  final NavTab tab;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _IconPainter(tab: tab, active: active, color: color),
    );
  }
}

class _IconPainter extends CustomPainter {
  const _IconPainter({required this.tab, required this.active, required this.color});
  final NavTab tab;
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sw = active ? 2.4 : 2.0;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withValues(alpha: active ? 0.12 : 0)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (tab) {
      case NavTab.home:
        final path = Path()
          ..moveTo(w * 0.125, h * 0.479)
          ..lineTo(w * 0.5, h * 0.167)
          ..lineTo(w * 0.875, h * 0.479)
          ..lineTo(w * 0.875, h * 0.833)
          ..quadraticBezierTo(w * 0.875, h * 0.875, w * 0.833, h * 0.875)
          ..lineTo(w * 0.625, h * 0.875)
          ..lineTo(w * 0.625, h * 0.625)
          ..lineTo(w * 0.375, h * 0.625)
          ..lineTo(w * 0.375, h * 0.875)
          ..lineTo(w * 0.167, h * 0.875)
          ..quadraticBezierTo(w * 0.125, h * 0.875, w * 0.125, h * 0.833)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case NavTab.chat:
        final path = Path()
          ..moveTo(w * 0.167, h * 0.25)
          ..quadraticBezierTo(w * 0.167, h * 0.167, w * 0.25, h * 0.167)
          ..lineTo(w * 0.75, h * 0.167)
          ..quadraticBezierTo(w * 0.833, h * 0.167, w * 0.833, h * 0.25)
          ..lineTo(w * 0.833, h * 0.625)
          ..quadraticBezierTo(w * 0.833, h * 0.708, w * 0.75, h * 0.708)
          ..lineTo(w * 0.458, h * 0.708)
          ..lineTo(w * 0.25, h * 0.854)
          ..lineTo(w * 0.25, h * 0.708)
          ..lineTo(w * 0.25, h * 0.708)
          ..quadraticBezierTo(w * 0.167, h * 0.708, w * 0.167, h * 0.625)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case NavTab.progress:
        for (final r in [
          Rect.fromLTWH(w * 0.167, h * 0.542, w * 0.167, h * 0.292),
          Rect.fromLTWH(w * 0.417, h * 0.333, w * 0.167, h * 0.5),
          Rect.fromLTWH(w * 0.667, h * 0.167, w * 0.167, h * 0.667),
        ]) {
          final rr = RRect.fromRectAndRadius(r, const Radius.circular(2));
          canvas.drawRRect(rr, fill);
          canvas.drawRRect(rr, stroke);
        }
      case NavTab.me:
        canvas.drawCircle(Offset(w * 0.5, h * 0.333), w * 0.167, fill);
        canvas.drawCircle(Offset(w * 0.5, h * 0.333), w * 0.167, stroke);
        final bodyPath = Path()
          ..moveTo(w * 0.167, h * 0.833)
          ..quadraticBezierTo(w * 0.292, h * 0.583, w * 0.5, h * 0.583)
          ..quadraticBezierTo(w * 0.708, h * 0.583, w * 0.833, h * 0.833);
        canvas.drawPath(bodyPath, stroke);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.tab != tab || old.active != active || old.color != color;
}
