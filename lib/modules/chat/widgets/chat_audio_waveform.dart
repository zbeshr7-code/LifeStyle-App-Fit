import 'dart:math';

import 'package:flutter/material.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class ChatAudioWaveform extends StatelessWidget {
  const ChatAudioWaveform({
    super.key,
    this.levels = const [],
    this.seed,
    this.progress = 0,
    this.barCount = 28,
    this.height = 28,
    this.color,
    this.inactiveColor,
    this.live = false,
  });

  final List<double> levels;
  final String? seed;
  final double progress;
  final int barCount;
  final double height;
  final Color? color;
  final Color? inactiveColor;
  final bool live;

  static List<double> levelsFromSeed(String value, int count) {
    final rng = Random(value.hashCode);
    return List.generate(count, (i) {
      final wave = sin(i * 0.55) * 0.18;
      return (0.35 + rng.nextDouble() * 0.45 + wave).clamp(0.18, 1.0);
    });
  }

  List<double> get _bars {
    if (levels.length >= barCount) {
      return levels.sublist(levels.length - barCount);
    }
    if (levels.isNotEmpty) {
      final padded = List<double>.filled(barCount, 0.15);
      final start = barCount - levels.length;
      for (var i = 0; i < levels.length; i++) {
        padded[start + i] = levels[i].clamp(0.12, 1.0);
      }
      return padded;
    }
    if (seed != null) {
      return levelsFromSeed(seed!, barCount);
    }
    return List<double>.filled(barCount, 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final bars = _bars;
    final playedBars = (progress.clamp(0.0, 1.0) * barCount).floor();
    final activeColor = color ?? AppColors.primary;
    final mutedColor = inactiveColor ?? AppColors.textSecondary;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final level = bars[index];
          final barHeight = (height * level).clamp(4.0, height);
          final isPlayed = !live && index < playedBars;
          final barColor = live || isPlayed
              ? activeColor
              : mutedColor.withValues(alpha: 0.45);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedContainer(
                duration: live
                    ? const Duration(milliseconds: 80)
                    : const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
