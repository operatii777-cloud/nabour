import 'package:flutter/material.dart';
import 'dart:async';

import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/rating_stars.dart';
import 'package:nabour_app/widgets/split_fare_widget.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/core/haptics/haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/content_filter.dart';

class RideSummaryScreen extends StatefulWidget {
  final String rideId;
  const RideSummaryScreen({super.key, required this.rideId});

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _commentController = TextEditingController();

  UserRole? _currentUserRole;
  bool _isRoleLoading = true;
  
  double _selectedRating = 0;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  
  // ✅ ADĂUGAT: Sistem de bacșiș pentru pasageri
  double _selectedTip = 0;
  final _customTipController = TextEditingController();

  late Future<Ride> _rideFuture;

  @override
  void initState() {
    super.initState();
    _rideFuture = _firestoreService.getRideStream(widget.rideId).first;
    _fetchUserRole();
  }

  // ✅ FIX: Timer pentru închiderea automată a pasagerului după 3 secunde
  Timer? _autoCloseTimer;

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _commentController.dispose();
    _customTipController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    try {
      final role = await _firestoreService.getUserRole();
      if (mounted) {
        setState(() {
          _currentUserRole = role;
          _isRoleLoading = false;
        });
      }
    } catch (e) {
      Logger.error("Error fetching user role: $e", error: e);
      if (mounted) {
        setState(() {
          _currentUserRole = UserRole.passenger; 
          _isRoleLoading = false;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_hasSubmitted || _isLoading) return;
    
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRating == 0) {
      _showSnackBar(l10n.pleaseSelectRatingBeforeSubmit);
      return;
    }

    // ── Filtru conținut ────────────────────────────────────────────────
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      final filterResult = ContentFilter.check(comment);
      if (!filterResult.isClean) {
        _showSnackBar(filterResult.message ?? 'Limbaj inadecvat în comentariu.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.submitRating(
        rideId: widget.rideId,
        rating: _selectedRating,
        comment: _commentController.text,
        tip: _selectedTip > 0 ? _selectedTip : null,
      );

      if (_currentUserRole == UserRole.passenger) {
        // Salvăm data ultimei curse pentru detecția inactivității
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_ride_date', DateTime.now().toIso8601String());
        } catch (_) {}
      }

      // ✅ FIX: Pornește timerul de închidere automată pentru pasageri
      unawaited(HapticService.instance.success());
      if (mounted) {
        setState(() {
          _hasSubmitted = true;
        });
        
        // 🔄 Timer pentru închiderea automată a pasagerului după 3 secunde
        if (_currentUserRole == UserRole.passenger) {
          _autoCloseTimer?.cancel();
          _autoCloseTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              _handleExit();
            }
          });
        } else {
          // ✅ FIX: Șoferul navighează automat în MapScreen după 1 secundă
          _autoCloseTimer?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _autoCloseTimer = Timer(const Duration(seconds: 1), () {
                if (mounted) {
                  _handleExit();
                }
              });
            }
          });
        }
      }
    } catch (e) {
      Logger.error('Error submitting rating: $e', error: e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(l10n.errorSubmittingRating);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleExit() {
    if (_isRoleLoading) return;

    try {
      // ✅ FIX: Atât pasagerul cât și șoferul navighează la MapScreen
      // Pasagerul poate comanda o altă cursă, șoferul poate prelua alte curse
      Logger.debug('Navigating to MapScreen...');
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      Logger.error('Error in _handleExit: $e', error: e);
      // ✅ FALLBACK: Încearcă să navigheze înapoi la ruta principală
      if (mounted) {
        try {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } catch (e2) {
          Logger.error('Fallback navigation also failed: $e2');
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentUserRole == UserRole.passenger, // ✅ FIX: Pasagerul poate închide, șoferul nu
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.rideSummary);
            },
          ),
          leading: _currentUserRole == UserRole.driver ? Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isRoleLoading ? null : _handleExit,
                tooltip: l10n.back,
              );
            },
          ) : null,
          automaticallyImplyLeading: false,
          actions: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isRoleLoading ? null : _handleExit,
                  tooltip: l10n.close,
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<Ride>(
          future: _rideFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isRoleLoading) {
              return _buildSkeleton();
            }
            
            if (!snapshot.hasData || snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(l10n.couldNotLoadRideDetails);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleExit,
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return Text(l10n.back);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // --- LOGICA NOUĂ PENTRU AFIȘARE ---
            // Dacă evaluarea a fost trimisă de un pasager, afișăm "La revedere!"
            if (_hasSubmitted && _currentUserRole == UserRole.passenger) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, size: 64, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'Vă mulțumim și la revedere!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTip > 0) 
                      Text(
                        'Bacșișul de ${_selectedTip.toStringAsFixed(0)} LEI a fost înregistrat.',
                        style: TextStyle(fontSize: 16, color: Colors.green.shade700),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Te redirecționăm la hartă în 3 secunde...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final ride = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Center(
                        child: Text(
                          l10n.thankYouForRide,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCard(ride),
                  const SizedBox(height: 32),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Center(
                        child: Text(
                          l10n.howWasExperience,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: RatingStars(
                      initialRating: _selectedRating,
                      onRatingChanged: (rating) {
                        if (mounted && !_hasSubmitted) {
                          setState(() {
                            _selectedRating = rating;
                          });
                        }
                      },
                    ),
                  ),
                  
                  // ✅ ASCUNS: Sistem de bacșiș și împărțire cost DOAR dacă nu este cursă gratuită
                  if (_currentUserRole == UserRole.passenger && ride.totalCost > 0) ...[
                    const SizedBox(height: 32),
                    _buildTipSection(),
                    const SizedBox(height: 16),
                    SplitFareWidget(
                      rideId: widget.rideId,
                      totalAmount: ride.totalCost,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return TextField(
                        controller: _commentController,
                        enabled: !_hasSubmitted,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: l10n.leaveCommentOptional,
                        ),
                        maxLines: 3,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  if (!_hasSubmitted) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Trimite Evaluarea',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleExit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Omite evaluarea',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Acest bloc va fi afișat doar pentru ȘOFER după trimitere
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Evaluarea a fost trimisă cu succes!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleExit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Înapoi la hartă',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title skeleton
          Center(child: _shimmerBox(width: 220, height: 26, radius: 8)),
          const SizedBox(height: 24),
          // Card skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8)],
            ),
            child: Column(children: [
              _shimmerBox(width: 120, height: 18, radius: 6),
              const SizedBox(height: 12),
              const Divider(),
              _shimmerRow(), const SizedBox(height: 10),
              _shimmerRow(), const SizedBox(height: 10),
              const Divider(),
              _shimmerRow(isWide: true),
            ]),
          ),
          const SizedBox(height: 32),
          // Rating label skeleton
          Center(child: _shimmerBox(width: 180, height: 18, radius: 6)),
          const SizedBox(height: 16),
          // Stars skeleton
          Center(child: _shimmerBox(width: 200, height: 40, radius: 20)),
          const SizedBox(height: 32),
          // Comment box skeleton
          _shimmerBox(width: double.infinity, height: 90, radius: 10),
          const SizedBox(height: 32),
          // Button skeleton
          _shimmerBox(width: double.infinity, height: 52, radius: 14),
          const SizedBox(height: 12),
          Center(child: _shimmerBox(width: 140, height: 20, radius: 6)),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height, required double radius}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      onEnd: () => setState(() {}),
    );
  }

  Widget _shimmerRow({bool isWide = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _shimmerBox(width: isWide ? 120 : 90, height: 14, radius: 4),
        _shimmerBox(width: isWide ? 140 : 80, height: 14, radius: 4),
      ],
    );
  }

  Widget _buildSummaryCard(Ride ride) {

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Detalii Cursă', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const Divider(),
            _buildDetailRow('Distanța:', '${ride.distance.toStringAsFixed(1)} km'),
            _buildDetailRow('Durata:', '${ride.durationInMinutes?.toStringAsFixed(0) ?? "0"} min'),
            const Divider(),
            if (ride.totalCost > 0)
              _buildDetailRow('Cost Total:', '${ride.totalCost.toStringAsFixed(2)} RON', isTotal: true)
            else
              _buildDetailRow('Cost Cursă:', 'Gratuit - Sprijin Vecini', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ✅ ADĂUGAT: Secțiunea de bacșiș pentru pasageri
  Widget _buildTipSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 Bacșiș pentru șofer (opțional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulțumește șoferului pentru o călătorie plăcută!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Butoane pentru sume predefinite
            Row(
              children: [
                Expanded(child: _buildTipButton(5)),
                const SizedBox(width: 8),
                Expanded(child: _buildTipButton(10)),
                const SizedBox(width: 8),
                Expanded(child: _buildTipButton(15)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Input pentru sumă custom
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTipController,
                    enabled: !_hasSubmitted,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Altă sumă (LEI)',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final customAmount = double.tryParse(value) ?? 0;
                      if (customAmount >= 0) {
                        setState(() { _selectedTip = customAmount; });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _hasSubmitted ? null : () {
                    setState(() { 
                      _selectedTip = 0; 
                      _customTipController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Fără bacșiș'),
                ),
              ],
            ),
            
            if (_selectedTip > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Bacșiș selectat: ${_selectedTip.toStringAsFixed(0)} LEI',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipButton(double amount) {
    final isSelected = _selectedTip == amount;
    return ElevatedButton(
      onPressed: _hasSubmitted ? null : () {
        setState(() { 
          _selectedTip = amount;
          _customTipController.clear();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text('${amount.toInt()} LEI'),
    );
  }
}