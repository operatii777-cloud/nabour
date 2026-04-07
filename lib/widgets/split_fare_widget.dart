import 'package:flutter/material.dart';
import 'package:nabour_app/services/split_fare_service.dart';

/// Widget that lets a passenger split a ride cost with contacts.
///
/// Displays a button; when tapped it opens a dialog where the user can
/// enter one or more email addresses. The cost is divided equally between
/// the initiator and all entered contacts.
///
/// Usage — drop into the ride summary / receipt screen:
/// ```dart
/// SplitFareWidget(rideId: rideId, totalAmount: ride.totalCost)
/// ```
class SplitFareWidget extends StatefulWidget {
  final String rideId;
  final double totalAmount;

  const SplitFareWidget({
    super.key,
    required this.rideId,
    required this.totalAmount,
  });

  @override
  State<SplitFareWidget> createState() => _SplitFareWidgetState();
}

class _SplitFareWidgetState extends State<SplitFareWidget> {
  final SplitFareService _service = SplitFareService();
  bool _splitInitiated = false;
  double? _amountPerPerson;
  int? _totalPeople;

  void _showSplitDialog() {
    final emailControllers = <TextEditingController>[
      TextEditingController(),
    ];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Împarte costul cursei'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost total: ${widget.totalAmount.toStringAsFixed(2)} RON',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adaugă adresele de email ale persoanelor cu care vrei să împarți.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ...emailControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Email contact ${index + 1}',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email obligatoriu';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(v.trim())) {
                                    return 'Email invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (emailControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    emailControllers.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          emailControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Adaugă contact'),
                    ),
                    const SizedBox(height: 8),
                    // Preview cost per person
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cost per persoană:'),
                          Text(
                            '${(widget.totalAmount / (emailControllers.length + 1)).toStringAsFixed(2)} RON',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Anulează'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final emails = emailControllers
                      .map((c) => c.text.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  Navigator.of(ctx).pop(emails);
                },
                child: const Text('Împarte'),
              ),
            ],
          );
        },
      ),
    ).then((emails) async {
      if (emails == null || emails is! List<String> || emails.isEmpty) return;
      try {
        await _service.initiateSplit(
            widget.rideId, emails, widget.totalAmount);
        final perPerson = widget.totalAmount / (emails.length + 1);
        if (mounted) {
          setState(() {
            _splitInitiated = true;
            _amountPerPerson = perPerson;
            _totalPeople = emails.length + 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Cost împărțit cu ${emails.length} contact(e). '
                'Fiecare plătește ${perPerson.toStringAsFixed(2)} RON.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Eroare: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_splitInitiated && _amountPerPerson != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.people, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cost împărțit',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  Text(
                    'Tu plătești: ${_amountPerPerson!.toStringAsFixed(2)} RON '
                    '(din ${_totalPeople!} persoane)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _showSplitDialog,
      icon: const Icon(Icons.people_outline),
      label: const Text('Împarte costul'),
    );
  }
}
