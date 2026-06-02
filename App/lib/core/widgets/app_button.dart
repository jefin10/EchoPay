import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'motion.dart';

/// The one primary call-to-action button for the whole app.
///
/// Ink fill, 16px radius, press-scale feedback (via [Pressable]), and a
/// built-in loading state that crossfades instead of snapping. Disabled
/// and loading both block the tap. Cohesion over per-screen styling.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.background,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final Color? background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final btn = Pressable(
      scale: 0.97,
      onTap: disabled ? () {} : onPressed!,
      child: AnimatedOpacity(
        opacity: disabled && !loading ? 0.45 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.out,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 22),
          decoration: BoxDecoration(
            color: background ?? AppColors.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.out,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foreground,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 10),
                        Icon(icon, size: 20, color: foreground),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
    if (!expand) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}
