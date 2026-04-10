import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

String firestoreStreamErrorMessage(
  Object? error, {
  required String fallback,
  String? permissionDeniedMessage,
}) {
  if (error is FirebaseException) {
    switch (error.code) {
      case "permission-denied":
        return permissionDeniedMessage ??
            "Acces refuzat. Verifică autentificarea sau regulile de securitate.";
      case "unavailable":
      case "deadline-exceeded":
        return "Serviciul este temporar indisponibil. Verifică conexiunea și încearcă din nou.";
      default:
        final m = error.message?.trim();
        return (m != null && m.isNotEmpty) ? m : error.code;
    }
  }
  return fallback;
}

class FirestoreStreamErrorCenter extends StatelessWidget {
  const FirestoreStreamErrorCenter({
    super.key,
    required this.error,
    required this.fallbackMessage,
    this.permissionDeniedMessage,
    this.icon = Icons.cloud_off_rounded,
  });

  final Object? error;
  final String fallbackMessage;
  final String? permissionDeniedMessage;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msg = firestoreStreamErrorMessage(
      error,
      fallback: fallbackMessage,
      permissionDeniedMessage: permissionDeniedMessage,
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: cs.tertiary),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
