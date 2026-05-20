import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// One motion language for the whole app.
///
/// A single strong ease-out curve and a small set of durations. Cohesion
/// over options — every screen should feel like the same hand made it.
class AppMotion {
  /// Strong ease-out — fast start, soft settle. The app-wide default.
  static const Curve out = Cubic(0.23, 1, 0.32, 1);

  /// Natural acceleration/deceleration for on-screen movement.
  static const Curve inOut = Cubic(0.77, 0, 0.175, 1);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration enter = Duration(milliseconds: 620);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// Wrap any tap target so it acknowledges the press: scale down on
/// press-down, snap back on release. ~120ms strong ease-out. Honors
/// reduced-motion (no scale, still tappable).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: (_down && !reduce) ? widget.scale : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.out,
        child: widget.child,
      ),
    );
  }
}

/// Sections fade + rise into place in sequence, once, on first paint.
/// Pass a controller you `forward()` after the first frame. Spacers
/// ([SizedBox]) ride with the element above them so they don't animate
/// independently. Falls back to a plain column under reduced-motion.
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.controller,
    required this.children,
    required this.enabled,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.step = 0.085,
  });

  final AnimationController controller;
  final List<Widget> children;
  final bool enabled;
  final CrossAxisAlignment crossAxisAlignment;
  final double step;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
    final groups = <List<Widget>>[];
    for (final w in children) {
      if (w is SizedBox && groups.isNotEmpty) {
        groups.last.add(w);
      } else {
        groups.add([w]);
      }
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < groups.length; i++)
          FadeRise(
            controller: controller,
            start: (i * step).clamp(0.0, 0.7),
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              children: groups[i],
            ),
          ),
      ],
    );
  }
}

/// A single fade + 14px rise driven by an [Interval] of [controller].
class FadeRise extends StatelessWidget {
  const FadeRise({
    super.key,
    required this.controller,
    required this.start,
    required this.child,
    this.distance = 14,
  });

  final AnimationController controller;
  final double start;
  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
          curve: AppMotion.out),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * distance),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Zero-boilerplate one-shot entrance: fade + rise, plays once when first
/// built, no controller or dispose needed. Use to wrap a screen's body so
/// it doesn't snap in. Honors reduced-motion.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.distance = 16,
  });

  final Widget child;
  final Duration delay;
  final double distance;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.enter,
      curve: Interval(
        // Map an optional pre-delay into the front of the curve.
        (delay.inMilliseconds / AppMotion.enter.inMilliseconds)
            .clamp(0.0, 0.6),
        1.0,
        curve: AppMotion.out,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * distance),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A flat placeholder block for skeleton loading states. Set [dark] on
/// dark surfaces.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
    this.dark = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Sweeps a soft highlight across [child] — use over [SkeletonBar]s
/// instead of a spinner. Static dimmed under reduced-motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return Opacity(opacity: 0.6, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = (rect.width + 220) * _c.value - 110;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx, rect.width),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx, this.width);
  final double dx;
  final double width;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx - width, 0, 0);
  }
}
