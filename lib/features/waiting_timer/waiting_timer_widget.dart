import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'waiting_timer_service.dart';

/// Widget afișat pe ecranul pasagerului și șoferului când șoferul a ajuns.
/// Pasager: vede countdown 2 min + taxa acumulată
/// Șofer: vede același timer pentru transparență
class WaitingTimerWidget extends StatelessWidget {
  const WaitingTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaitingTimerService>(
      builder: (_, service, __) {
        final state = service.state;
        if (!state.isActive) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: state.isFreeWaitingExpired
                ? Colors.orange.shade50
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: state.isFreeWaitingExpired
                  ? Colors.orange.shade300
                  : Colors.blue.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: state.isFreeWaitingExpired
                    ? Colors.orange
                    : Colors.blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isFreeWaitingExpired
                          ? 'Taxa de așteptare activă'
                          : 'Șoferul te așteaptă',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      state.isFreeWaitingExpired
                          ? 'Timp gratuit expirat'
                          : '${state.remainingFreeSeconds}s gratuit rămase',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.formattedElapsed,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: state.isFreeWaitingExpired
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                  if (state.isFreeWaitingExpired)
                    Text(
                      '+${state.currentCharge.toStringAsFixed(2)} RON',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
