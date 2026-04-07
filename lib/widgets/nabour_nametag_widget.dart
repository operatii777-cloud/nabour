import 'package:flutter/material.dart';
import 'package:nabour_app/utils/nametag_helper.dart';

/// Afișează avatarul + prenumele unui user Nabour.
///
/// Variante:
///   [NabourNametagWidget.bubble] — cerc colorat cu emoji, pentru hartă/chat
///   [NabourNametagWidget.inline] — emoji + text pe linie, pentru liste
///   [NabourNametagWidget.large]  — cerc mare pentru profilul utilizatorului
class NabourNametagWidget extends StatelessWidget {
  final String avatar;      // emoji animal
  final String displayName;
  final _Style _style;
  final double? size;
  final Color? backgroundColor;

  const NabourNametagWidget.bubble({
    super.key,
    required this.avatar,
    required this.displayName,
    this.size,
    this.backgroundColor,
  }) : _style = _Style.bubble;

  const NabourNametagWidget.inline({
    super.key,
    required this.avatar,
    required this.displayName,
    this.size,
    this.backgroundColor,
  }) : _style = _Style.inline;

  const NabourNametagWidget.large({
    super.key,
    required this.avatar,
    required this.displayName,
    this.size,
    this.backgroundColor,
  }) : _style = _Style.large;

  /// Construiește widget-ul din datele Firestore ale unui user.
  factory NabourNametagWidget.fromData(
    Map<String, dynamic>? data, {
    Key? key,
    bool large = false,
    bool inline = false,
  }) {
    final avatar = data?['avatar'] as String? ?? '🙂';
    final name = data?['displayName'] as String? ?? 'Vecin';
    if (large) return NabourNametagWidget.large(key: key, avatar: avatar, displayName: name);
    if (inline) return NabourNametagWidget.inline(key: key, avatar: avatar, displayName: name);
    return NabourNametagWidget.bubble(key: key, avatar: avatar, displayName: name);
  }

  String get _firstName => displayName.split(' ').first;
  String get nametag => NabourNametag.build(avatar, displayName);

  @override
  Widget build(BuildContext context) {
    switch (_style) {
      case _Style.bubble:
        return _Bubble(avatar: avatar, name: _firstName,
            size: size ?? 44, bg: backgroundColor);
      case _Style.inline:
        return _Inline(avatar: avatar, name: _firstName, size: size ?? 14);
      case _Style.large:
        return _Large(avatar: avatar, name: _firstName,
            size: size ?? 80, bg: backgroundColor);
    }
  }
}

enum _Style { bubble, inline, large }

// ── Bubble: cerc cu emoji, folosit pe hartă și în chat ────────────────────

class _Bubble extends StatelessWidget {
  final String avatar;
  final String name;
  final double size;
  final Color? bg;

  const _Bubble({required this.avatar, required this.name,
      required this.size, this.bg});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg ?? const Color(0xFF7C3AED).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(avatar,
                style: TextStyle(fontSize: size * 0.52)),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Inline: emoji + text pe aceeași linie, pentru liste ──────────────────

class _Inline extends StatelessWidget {
  final String avatar;
  final String name;
  final double size;

  const _Inline({required this.avatar, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(avatar, style: TextStyle(fontSize: size + 2)),
        const SizedBox(width: 5),
        Text(
          name,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

// ── Large: pentru ecranul de profil ──────────────────────────────────────

class _Large extends StatelessWidget {
  final String avatar;
  final String name;
  final double size;
  final Color? bg;

  const _Large({required this.avatar, required this.name,
      required this.size, this.bg});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F5FF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(avatar,
                style: TextStyle(fontSize: size * 0.50)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
