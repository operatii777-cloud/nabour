import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/auth_screen.dart';
import 'package:nabour_app/screens/change_password_screen.dart';
import 'package:nabour_app/services/account_service.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.securityAndSafety),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // ── Password ────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text(l10n.changePassword),
            subtitle: Text(l10n.changePasswordSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ChangePasswordScreen()),
              );
            },
          ),

          const Divider(),

          // ── Session management ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.sessions,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: Text(l10n.logoutAllDevices),
            subtitle: Text(l10n.logoutAllDevicesSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _confirmLogoutAllDevices(context),
          ),

          const Divider(),

          // ── Danger zone ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.dangerZone,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(l10n.deleteAccountSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  // ── Logout all devices ─────────────────────────────────────────────────────

  void _confirmLogoutAllDevices(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmLogoutAllDevicesTitle),
        content: Text(l10n.confirmLogoutAllDevicesContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.of(dialogContext).pop();

              try {
                await AccountService().logoutAllDevices();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                AppFeedback.error(context, l10n.errorPrefix(e));
              }
            },
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );
  }

  // ── Delete account ─────────────────────────────────────────────────────────

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Only offer password re-auth for email/password providers
    final user = FirebaseAuth.instance.currentUser;
    final isEmailUser = user?.providerData
            .any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID) ??
        false;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.permanentDeleteAccount),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                l10n.attention,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.willBeDeletedTitle}\n'
                '${l10n.willBeDeletedProfile}\n'
                '${l10n.willBeDeletedRideHistory}\n'
                '${l10n.willBeDeletedData}',
              ),
              if (isEmailUser) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.accountPassword,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.enterPasswordConfirm
                      : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final navigator = Navigator.of(context);
              Navigator.of(dialogContext).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final result = await AccountService()
                  .deleteAccount(passwordController.text);

              navigator.pop(); // close loading indicator
              if (!context.mounted) return;

              if (result['success'] == true) {
                AppFeedback.success(context, result['message'] as String);
                if (!context.mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                  (route) => false,
                );
              } else {
                AppFeedback.error(context, result['message'] as String);
              }
            },
            child: Text(
              l10n.deleteAccountButton,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
