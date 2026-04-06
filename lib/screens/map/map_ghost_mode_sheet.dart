/// Ghost mode bottom sheet for visibility duration selection.

import 'package:flutter/material.dart';
import 'map_screen_constants.dart';

class GhostModeSheet extends StatelessWidget {
  const GhostModeSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('👥', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Cât timp ești vizibil vecinilor?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Vecinii te vor vedea ca bulă pe hartă.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          DurationTile(
            icon: '⏰',
            label: '1 oră',
            sub: 'Util pentru o ieșire scurtă',
            duration: const Duration(hours: 1),
          ),
          DurationTile(
            icon: '🕓',
            label: '4 ore',
            sub: 'Util pentru o după-amiază',
            duration: const Duration(hours: 4),
          ),
          DurationTile(
            icon: '🌙',
            label: 'Până mâine',
            sub: 'Se resetează la miezul nopții',
            duration: Duration(
              hours: 23 - DateTime.now().hour,
              minutes: 59 - DateTime.now().minute,
            ),
          ),
          DurationTile(
            icon: '♾️',
            label: 'Permanent',
            sub: 'Rămâi vizibil până dezactivezi manual',
            duration: Duration.zero, // sentinel = permanent
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          DurationTile(
            icon: '🫥',
            label: 'Invizibil (mod fantomă)',
            sub: 'Nu apari pe hartă; profilul marchează ghostMode în cont (sync între dispozitive).',
            duration: kInvisibleChoice,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class DurationTile extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final Duration duration;
  final bool isDestructive;

  const DurationTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.duration,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : const Color(0xFF7C3AED);
    return ListTile(
      dense: true,
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDestructive ? Colors.red.shade700 : null)),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: () => Navigator.of(context).pop(duration),
    );
  }
}
