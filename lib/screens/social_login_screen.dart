import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nabour_app/services/social_auth_service.dart';
import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  final SocialAuthService _authService = SocialAuthService();
  bool _loading = false;

  Future<void> _signIn(Future<dynamic> Function() action) async {
    setState(() => _loading = true);
    try {
      final result = await action();
      if (result != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFacebookPage() async {
    setState(() => _loading = true);
    try {
      final url = Environment.facebookPageUrl;
      if (url.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facebook vine curând pentru promovare.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Nu s-a putut deschide $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare Facebook: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              const Text('Bun venit!', style: AppTextStyles.heading1),
              const SizedBox(height: 10),
              Text(
                'Autentifică-te pentru a continua',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              if (_loading)
                const CircularProgressIndicator()
              else ...[
                // Google
                _SocialButton(
                  onPressed: () =>
                      _signIn(() => _authService.signInWithGoogle()),
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: 'Continuă cu Google',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  borderColor: AppColors.border,
                ),
                const SizedBox(height: 14),

                // Apple (iOS only)
                if (Platform.isIOS) ...[
                  _SocialButton(
                    onPressed: () =>
                        _signIn(() => _authService.signInWithApple()),
                    icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                    label: 'Continuă cu Apple',
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                ],

                // Facebook
                _SocialButton(
                  onPressed: _openFacebookPage,
                  icon: const Icon(Icons.facebook, size: 24, color: Colors.white),
                  label: 'Continuă cu Facebook',
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('sau',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Guest button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text('Continuă ca oaspete',
                        style: AppTextStyles.button
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor)),
          ],
        ),
      ),
    );
  }
}
