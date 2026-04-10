import 'package:flutter/material.dart';
import 'package:nabour_app/theme/app_colors.dart';

/// Mesaje scurte, consistente vizual și accesibile (contrast, flotant, margini).
///
/// Folosiți în loc de [SnackBar] ad-hoc pentru același comportament în tot proiectul.
abstract final class AppFeedback {
  AppFeedback._();

  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _shortDuration = Duration(seconds: 2);

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final bg = backgroundColor ?? Theme.of(context).snackBarTheme.backgroundColor;
    final themeFg =
        Theme.of(context).snackBarTheme.contentTextStyle?.color ?? Colors.white;
    // Pe fundal colorat (success/eroare) folosim mereu text alb pentru contrast.
    final fg = backgroundColor != null ? Colors.white : themeFg;

    messenger.showSnackBar(
      SnackBar(
        content: DefaultTextStyle.merge(
          style: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
          child: icon == null
              ? Text(message)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: fg, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(message)),
                  ],
                ),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: duration ?? _defaultDuration,
        action: action,
        showCloseIcon: action == null,
        closeIconColor: fg.withValues(alpha: 0.92),
      ),
    );
  }

  static void success(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
      duration: duration ?? _shortDuration,
    );
  }

  static void error(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      duration: duration ?? _defaultDuration,
    );
  }

  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
      duration: duration ?? _defaultDuration,
    );
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      backgroundColor: AppColors.violetAccent,
      icon: Icons.info_outline_rounded,
      duration: duration ?? _shortDuration,
    );
  }
}
