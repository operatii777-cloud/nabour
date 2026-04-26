import 'package:flutter/material.dart';
import 'cancellation_model.dart';

/// Dialog modal obligatoriu când șoferul anulează o cursă acceptată.
/// Returnează motivul ales sau null dacă a apăsat "Înapoi".
class CancellationDialog extends StatefulWidget {
  const CancellationDialog({super.key});

  static Future<CancellationReason?> show(BuildContext context) {
    return showDialog<CancellationReason>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CancellationDialog(),
    );
  }

  @override
  State<CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<CancellationDialog> {
  CancellationReason? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'De ce anulezi cursa?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selectarea unui motiv ne ajută să îmbunătățim experiența.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            RadioGroup<CancellationReason>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CancellationReason.values.map(
                  (reason) => RadioListTile<CancellationReason>(
                    title: Text(
                      reason.label,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: reason,
                    contentPadding: EdgeInsets.zero,
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Înapoi'),
        ),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text(
            'Confirmă anularea',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
