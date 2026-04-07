import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nabour_app/widgets/voice_input_button.dart';

class EditAddressScreen extends StatefulWidget {
  final SavedAddress address;
  
  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address.label);
    _addressController = TextEditingController(text: widget.address.address);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // Validăm noua adresă dacă s-a schimbat
      GeoPoint coordinates = widget.address.coordinates;
      
      if (_addressController.text != widget.address.address) {
        final List<Location> locations = await locationFromAddress(_addressController.text);
        if (locations.isEmpty) {
          throw Exception("Adresa nu a putut fi validată. Vă rugăm introduceți o adresă mai precisă.");
        }
        final location = locations.first;
        coordinates = GeoPoint(location.latitude, location.longitude);
      }
      
      // Actualizăm adresa
      await _firestoreService.updateSavedAddress(
        widget.address.id,
        SavedAddress(
          id: widget.address.id,
          label: _labelController.text,
          address: _addressController.text,
          coordinates: coordinates,
        ),
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresa a fost actualizată cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Eroare: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificăm dacă e adresă sistem (Acasă/Serviciu)
    final isSystemAddress = widget.address.label.toLowerCase() == 'acasă' || 
                          widget.address.label.toLowerCase() == 'serviciu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editează Adresa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _labelController,
                enabled: !isSystemAddress, // Nu permitem editarea etichetei pentru Acasă/Serviciu
                decoration: InputDecoration(
                  labelText: 'Etichetă (ex: Mama, Bunici, Sala)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label_outline),
                  helperText: isSystemAddress ? 'Eticheta nu poate fi modificată' : null,
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Eticheta este obligatorie.' : null,
              ),
              const SizedBox(height: 16),
              // Top row: label + voice + map
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Adresă completă',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceInputButton(
                        onSpeechResult: (transcription) {
                          _addressController.text = transcription;
                          setState(() {});
                        },
                        onSpeechError: (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Eroare la recunoașterea vocală: $error'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        size: 32,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.map_outlined, color: Colors.grey),
                        tooltip: 'Alege de pe hartă',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcționalitatea de hartă va fi implementată în curând'),
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Adresa este obligatorie.' : null,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _updateAddress,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvează Modificările'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}