import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/providers/assistant_status_provider.dart';

class AssistantStatusOverlay extends StatelessWidget {
  const AssistantStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssistantStatusProvider>(
      builder: (context, statusProvider, _) {
        if (!statusProvider.overlayEnabled) return const SizedBox.shrink();
        final isWorking = statusProvider.status == AssistantWorkStatus.working;
        return Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(179),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWorking ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isWorking ? 'Lucrez' : 'Aștept comenzi',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



