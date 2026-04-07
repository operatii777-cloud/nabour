import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/support_ticket_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportFormScreen extends StatefulWidget {
  final String reportType;

  const ReportFormScreen({super.key, required this.reportType});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _selectedRideId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportType),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vă rugăm să ne oferiți cât mai multe detalii despre ${widget.reportType.toLowerCase()}.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              // Dropdown pentru a selecta o cursă relevantă
              StreamBuilder<List<Ride>>(
                stream: _firestoreService.getRidesHistory(), // Refolosim funcția existentă
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink(); // Nu afișăm nimic dacă nu există istoric
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedRideId,
                    decoration: const InputDecoration(
                      labelText: 'Selectează cursa relevantă (Opțional)',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((ride) {
                      return DropdownMenuItem(
                        value: ride.id,
                        child: Text(
                          'Către: ${ride.destinationAddress}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRideId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Descrieți problema aici',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Vă rugăm oferiți o descriere de cel puțin 10 caractere.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Trimite Raportul'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final ticket = SupportTicket(
      userId: '', // FirestoreService va suprascrie acest câmp
      reportType: widget.reportType,
      message: _messageController.text,
      rideId: _selectedRideId,
      timestamp: Timestamp.now(),
    );

    try {
      await _firestoreService.submitSupportTicket(ticket);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raportul a fost trimis cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A apărut o eroare: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}