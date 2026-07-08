import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';

/// Accent, orb style and bubble style are switchable in Tweaks — the board's
/// one sanctioned piece of personalisation. Everything else stays fixed.
class AccentChoice {
  const AccentChoice(this.name, this.color);

  final String name;
  final Color color;
}

const accentChoices = [
  AccentChoice('ELECTRIC', WhoomzPalette.electric),
  AccentChoice('VIOLET', Color(0xFF7A2BF5)),
  AccentChoice('EMBER', Color(0xFFE8590C)),
];

enum OrbStyle { filled, ring }

enum BubbleStyle { ink, outline }

class TweaksState {
  const TweaksState({
    this.accentIndex = 0,
    this.orbStyle = OrbStyle.filled,
    this.bubbleStyle = BubbleStyle.ink,
  });

  final int accentIndex;
  final OrbStyle orbStyle;
  final BubbleStyle bubbleStyle;

  AccentChoice get accent => accentChoices[accentIndex % accentChoices.length];

  TweaksState copyWith({
    int? accentIndex,
    OrbStyle? orbStyle,
    BubbleStyle? bubbleStyle,
  }) => TweaksState(
    accentIndex: accentIndex ?? this.accentIndex,
    orbStyle: orbStyle ?? this.orbStyle,
    bubbleStyle: bubbleStyle ?? this.bubbleStyle,
  );
}

final tweaksProvider = NotifierProvider<TweaksController, TweaksState>(
  TweaksController.new,
);

class TweaksController extends Notifier<TweaksState> {
  static const _accentKey = 'tweaks_accent';
  static const _orbKey = 'tweaks_orb';
  static const _bubbleKey = 'tweaks_bubble';

  @override
  TweaksState build() {
    _load();
    return const TweaksState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TweaksState(
      accentIndex: prefs.getInt(_accentKey) ?? 0,
      orbStyle: OrbStyle.values[prefs.getInt(_orbKey) ?? 0],
      bubbleStyle: BubbleStyle.values[prefs.getInt(_bubbleKey) ?? 0],
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, state.accentIndex);
    await prefs.setInt(_orbKey, state.orbStyle.index);
    await prefs.setInt(_bubbleKey, state.bubbleStyle.index);
  }

  void cycleAccent() {
    state = state.copyWith(
      accentIndex: (state.accentIndex + 1) % accentChoices.length,
    );
    _save();
  }

  void cycleOrb() {
    state = state.copyWith(
      orbStyle:
          OrbStyle.values[(state.orbStyle.index + 1) % OrbStyle.values.length],
    );
    _save();
  }

  void cycleBubble() {
    state = state.copyWith(
      bubbleStyle: BubbleStyle
          .values[(state.bubbleStyle.index + 1) % BubbleStyle.values.length],
    );
    _save();
  }
}
