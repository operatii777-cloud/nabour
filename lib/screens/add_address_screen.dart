// lib/screens/add_address_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/screens/map_picker_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import '../utils/deprecated_apis_fix.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/widgets/voice_input_button.dart';

class AddAddressScreen extends StatefulWidget {
  final SavedAddress? addressToEdit;
  final String? initialLabel; // ✅ NOU: Label precompletat pentru adrese noi
  /// Categorie la adăugare (ex. Acasă / Serviciu din fluxul de curse).
  final SavedAddressCategory? initialCategory;
  /// Punct de pe hartă / reverse geocoding — același flux ca la selectarea destinației.
  final GeoPoint? prefilledCoordinates;
  final String? prefilledAddress;

  const AddAddressScreen({
    super.key,
    this.addressToEdit,
    this.initialLabel,
    this.initialCategory,
    this.prefilledCoordinates,
    this.prefilledAddress,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  Timer? _debounce;
  late SavedAddressCategory _category;
  
  // Starea validării adresei
  AddressValidationState _validationState = AddressValidationState.initial;
  String? _validationMessage;
  GeoPoint? _selectedCoordinates;

  bool get _isEditing => widget.addressToEdit != null;

  @override
  void initState() {
    super.initState();
    _category = widget.addressToEdit?.category ??
        widget.initialCategory ??
        SavedAddressCategory.other;
    // Pre-populăm câmpurile dacă edităm
    if (_isEditing) {
      _labelController.text = widget.addressToEdit!.label;
      _addressController.text = widget.addressToEdit!.address;
      _selectedCoordinates = widget.addressToEdit!.coordinates;
      _validationState = AddressValidationState.valid;
    } else if (widget.initialLabel != null) {
      // ✅ NOU: Precompletează label-ul dacă este furnizat
      _labelController.text = widget.initialLabel!;
    }

    if (!_isEditing &&
        widget.prefilledCoordinates != null &&
        widget.prefilledAddress != null &&
        widget.prefilledAddress!.trim().isNotEmpty) {
      _selectedCoordinates = widget.prefilledCoordinates;
      _addressController.text = widget.prefilledAddress!.trim();
      _validationState = AddressValidationState.valid;
      _validationMessage = 'Locație de pe hartă';
    }
    
    // Listener pentru validarea în timp real
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged() {
    // Resetăm starea când utilizatorul modifică textul
    if (_validationState != AddressValidationState.typing && _addressController.text.isNotEmpty) {
      setState(() {
        _validationState = AddressValidationState.typing;
        _validationMessage = null;
      });
    }

    // Debounce pentru validarea automată
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (_addressController.text.length < 3) {
      setState(() {
        _validationState = AddressValidationState.initial;
        _validationMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () {
      _validateAddressLive();
    });
  }

  Future<void> _validateAddressLive() async {
    if (!mounted || _addressController.text.length < 3) return;
    
    setState(() {
      _validationState = AddressValidationState.validating;
    });

    try {
      final List<Location> locations = await locationFromAddress(_addressController.text);
      
      if (!mounted) return;
      
      if (locations.isNotEmpty) {
        setState(() {
          _validationState = AddressValidationState.valid;
          _validationMessage = "Adresă validă și găsită pe hartă";
          _selectedCoordinates = GeoPoint(locations.first.latitude, locations.first.longitude);
        });
      } else {
        setState(() {
          _validationState = AddressValidationState.invalid;
          _validationMessage = "Adresa nu a fost găsită pe hartă";
          _selectedCoordinates = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationState = AddressValidationState.invalid;
        _validationMessage = "Nu s-a putut verifica adresa";
        _selectedCoordinates = null;
      });
    } finally {
      if (mounted) {
        // Starea de validare este deja setată în blocurile de mai sus
      }
    }
  }

  Future<void> _selectFromMap() async {
    try {
      // Obținem locația curentă pentru inițializarea hărții
      final currentPosition = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(initialLocation: currentPosition),
        ),
      );

      if (result != null && result.containsKey('location') && result.containsKey('address') && mounted) {
        final selectedPoint = result['location'] as Point;
        final selectedAddress = result['address'] as String;
        
        setState(() {
          _addressController.text = selectedAddress;
          _selectedCoordinates = GeoPoint(
            selectedPoint.coordinates.lat.toDouble(),
            selectedPoint.coordinates.lng.toDouble(),
          );
          _validationState = AddressValidationState.valid;
          _validationMessage = "Locație selectată de pe hartă";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nu s-a putut deschide harta: ${e.toString()}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verificăm că avem coordonate valide
    if (_selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Te rugăm să validezi adresa sau să o selectezi de pe hartă."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final addressData = SavedAddress(
        id: _isEditing ? widget.addressToEdit!.id : '',
        label: _labelController.text.trim(),
        address: _addressController.text.trim(),
        coordinates: _selectedCoordinates!,
        category: _category,
      );

      if (_isEditing) {
        await _firestoreService.updateSavedAddress(addressData.id, addressData);
      } else {
        await _firestoreService.addSavedAddress(addressData);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Adresa a fost actualizată!' : 'Adresa a fost salvată!'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editează Adresa' : 'Adaugă Adresă Nouă'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Câmpul pentru etichetă
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Etichetă (ex: Acasă, Serviciu, Prieteni)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) 
                    ? 'Eticheta este obligatorie.' : null,
              ),
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Categorie',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SavedAddressCategory.values.map((c) {
                  final selected = _category == c;
                  return ChoiceChip(
                    label: Text(c.labelRo),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _category = c;
                        final t = _labelController.text.trim();
                        if (t.isEmpty) {
                          if (c == SavedAddressCategory.home) {
                            _labelController.text = 'Acasă';
                          } else if (c == SavedAddressCategory.work) {
                            _labelController.text = 'Serviciu';
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              
              // Câmpul pentru adresă cu validare în timp real
              // Top row: label bold + voice + map + validation indicator
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
                          _validateAddressLive();
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
                      const SizedBox(width: 8),
                      _buildValidationIndicator(),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.map_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: _selectFromMap,
                        tooltip: 'Alege de pe hartă',
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
                validator: (value) => (value == null || value.trim().isEmpty) 
                    ? 'Adresa este obligatorie.' : null,
              ),
              
              // Mesaj de validare
              if (_validationMessage != null) ...[
                const SizedBox(height: 8),
                _buildValidationMessage(),
              ],
              
              const SizedBox(height: 24),
              
              // Buton de salvare
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _validationState == AddressValidationState.valid ? _saveAddress : null,
                  icon: Icon(_isEditing ? Icons.update : Icons.save_outlined),
                  label: Text(_isEditing ? 'Actualizează Adresa' : 'Salvează Adresa'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _validationState == AddressValidationState.valid 
                        ? null 
                        : Colors.grey.shade400,
                  ),
                ),
              
              if (_validationState != AddressValidationState.valid) ...[
                const SizedBox(height: 12),
                Text(
                  'Validează adresa sau selectează de pe hartă pentru a putea salva.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationIndicator() {
    switch (_validationState) {
      case AddressValidationState.initial:
        return const SizedBox.shrink();
      case AddressValidationState.typing:
        return Icon(Icons.edit, color: Colors.grey.shade400, size: 20);
      case AddressValidationState.validating:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case AddressValidationState.valid:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case AddressValidationState.invalid:
        return const Icon(Icons.error, color: Colors.red, size: 20);
    }
  }

  Widget _buildValidationMessage() {
    Color messageColor;
    IconData messageIcon;
    
    switch (_validationState) {
      case AddressValidationState.valid:
        messageColor = Colors.green;
        messageIcon = Icons.check_circle_outline;
        break;
      case AddressValidationState.invalid:
        messageColor = Colors.red;
        messageIcon = Icons.error_outline;
        break;
      default:
        messageColor = Colors.orange;
        messageIcon = Icons.info_outline;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: messageColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: messageColor.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(messageIcon, color: messageColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationMessage!,
              style: TextStyle(color: messageColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

enum AddressValidationState {
  initial,    // Starea inițială, fără validare
  typing,     // Utilizatorul scrie
  validating, // Se validează adresa
  valid,      // Adresa este validă
  invalid,    // Adresa este invalidă
}