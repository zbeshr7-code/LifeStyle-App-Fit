import 'package:flutter/material.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.surfaceSolid;
    final highlight = widget.highlightColor ?? AppColors.inputFill;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.lg,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceSolid,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class HomeProfileShimmer extends StatelessWidget {
  const HomeProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      ShimmerBox(width: double.infinity, height: 28),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 180, height: 16),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const ShimmerBox(
                  width: 48,
                  height: 48,
                  borderRadius: AppRadius.pill,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 88),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 88),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerBox(width: 120, height: 18),
                const SizedBox(height: AppSpacing.md),
                const ShimmerBox(width: double.infinity, height: 72),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerBox(width: double.infinity, height: 72),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerBox(width: double.infinity, height: 72),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
