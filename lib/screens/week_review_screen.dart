import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gal/gal.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/deprecated_apis_fix.dart';
import 'package:nabour_app/services/movement_history_service.dart';





/// Ecranul de prezentare stil "BUMP" pentru Week Recap.
/// Folosește Mapbox Globe Projection și animații de cameră pentru un efect cinematic.
class WeekReviewScreen extends StatefulWidget {
  const WeekReviewScreen({super.key});

  @override
  State<WeekReviewScreen> createState() => _WeekReviewScreenState();
}

class _WeekReviewScreenState extends State<WeekReviewScreen> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  Timer? _animTimer;
  
  // Audio players pentru sound effects
  final AudioPlayer _spinPlayer = AudioPlayer();
  final AudioPlayer _popPlayer = AudioPlayer();
  
  // Animația barei de progres (ca la stories)
  late AnimationController _progressController;

  // Stadiul recensământului
  int _currentStep = 0;
  bool _isMapReady = false;
  bool _isPaused = false; // ✅ NOU: Control pauză
  double _playbackSpeed = 1.0;
  bool _isLoading = true;
  List<Position> _storyPoints = [];

  // Profilul utilizatorului
  String _userInitial = 'N';

  // Perioada selectată (default: ultimele 7 zile)
  late DateTime _rangeFrom;
  late DateTime _rangeTo;

  @override
  void initState() {
    super.initState();

    // Perioada default: ultima săptămână
    _rangeTo = DateTime.now();
    _rangeFrom = _rangeTo.subtract(const Duration(days: 7));

    // Inițiala utilizatorului din profilul Firebase Auth
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _userInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N';

    // Inițializare controller progres
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    // Durata poveștii calculată pe pași (aprox 14 secunde total)
    // NU mai ieșim automat (userul închide când dorește)
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Rămânem la ultimul cadru pentru admirație
      }
    });

    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() => _isLoading = true);

    try {
      final summaries = await MovementHistoryService.instance.loadRange(
        from: _rangeFrom,
        to: _rangeTo,
      );

      final samples = summaries.expand((e) => e.path).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (samples.isEmpty) {
        // Fallback la puncte de test dacă nu există date reale, dar informăm log-ul
        Logger.info('WeekReview: No real samples found, using fallback.');
        _storyPoints = [
          Position(26.1025, 44.4268),
          Position(26.0900, 44.4320),
          Position(26.1150, 44.4150),
          Position(26.0825, 44.4400),
          Position(26.1200, 44.4100),
          Position(26.0950, 44.4220),
        ];
      } else {
        // Reducem numărul de puncte pentru o animație fluidă (max 12 puncte cheie)
        final List<Position> points = [];
        if (samples.length <= 12) {
          points.addAll(samples.map((s) => Position(s.longitude, s.latitude)));
        } else {
          final stride = (samples.length / 12).floor();
          for (var i = 0; i < samples.length; i += stride) {
            points.add(Position(samples[i].longitude, samples[i].latitude));
            if (points.length >= 12) break;
          }
          // Asigurăm ultimul punct
          if (points.last.lng != samples.last.longitude || points.last.lat != samples.last.latitude) {
            points.add(Position(samples.last.longitude, samples.last.latitude));
          }
        }
        _storyPoints = points;
      }
    } catch (e) {
      Logger.error('Error loading real data for WeekReview: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_isMapReady) {
        _startStorySequence();
      }
    }
  }

  void _replay() async {
    if (!mounted) return;
    
    // Oprim totul
    _animTimer?.cancel();
    _progressController.stop();
    _progressController.reset();
    
    // Resetăm starea UI
    setState(() {
      _currentStep = 0;
      _isPaused = false;
    });

    // Ștergem adnotările de pe hartă
    if (_circleAnnotationManager != null) {
      await _circleAnnotationManager!.deleteAll();
    }
    if (_polylineAnnotationManager != null) {
      await _polylineAnnotationManager!.deleteAll();
    }

    // Repornim secvența
    _startStorySequence();
  }

  void _togglePlayPause() {
    if (!mounted) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _progressController.stop();
        _spinPlayer.pause();
        _popPlayer.pause();
      } else {
        _progressController.forward();
        // Resumăm sunetul dacă este cazul
      }
    });
  }

  void _updatePlaybackSpeed(double speed) {
    if (!mounted) return;
    setState(() {
      _playbackSpeed = speed;
      // Ajustăm durata animației curente
      _progressController.duration = Duration(milliseconds: (14000 / _playbackSpeed).round());
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _progressController.dispose();
    _spinPlayer.dispose();
    _popPlayer.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Mapbox v11 default styles (like dark-v11) use globe projection automatically at low zoom!
    // We just zoom out to show it.
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        pitchEnabled: false,
        scrollEnabled: false,
        rotateEnabled: false,
        doubleTapToZoomInEnabled: false,
        doubleTouchToZoomOutEnabled: false,
        pinchToZoomEnabled: false,
      ),
    );

    // Ascundem elementele UI (busolă, scală, etc.)
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));

    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    setState(() {
      _isMapReady = true;
    });

    // Începem secvența povestirii doar dacă datele sunt gata
    if (!_isLoading) {
      _startStorySequence();
    }
  }

  // Eliminăm lista statică de rute/locații hardcodate

  void _startStorySequence() {
    if (_mapboxMap == null) return;

    _progressController.forward();

    // Pasul 0: Vedere din spațiu către America (zoom mic)
    _mapboxMap!.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(-98.5795, 39.8283)), // Centrul SUA
        zoom: 1.5,
        pitch: 0.0,
        bearing: 0.0,
      ),
    );

    // După 1.5 secunde, lansăm flyTo către PRIMA locație (fotorealist la nivel de stradă)
    _animTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      
      setState(() => _currentStep = 1); // "Ne apropiem"

      // Zburăm către primul punct al cursei din săptămână
      _spinPlayer.play(AssetSource('sounds/recap_wind.mp3'));
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: _storyPoints.first),
          zoom: 14.8,   // Nivel stradă
          pitch: 55.0, 
          bearing: 15.0, 
        ),
        MapAnimationOptions(duration: (3500 / _playbackSpeed).round()), // Scalat cu viteză
      );

      // După ce aterizăm, începem construcția prin puncte + linii
      if (mounted) {
        _buildPressurePoints();
      }
    });
  }

  Future<void> _buildPressurePoints() async {
    if (_circleAnnotationManager == null || _polylineAnnotationManager == null) return;
    
    setState(() => _currentStep = 2);

    final List<Position> drawnPositions = [];
    PolylineAnnotation? routeLine; // Singura linie neon — actualizată progresiv

    // Extragem calculul mediei locațiilor pentru zoom-out-ul zonal ulterior
    double sumLat = 0, sumLng = 0;
    for (var p in _storyPoints) { sumLng += p.lng; sumLat += p.lat; }
    final centerBox = Point(coordinates: Position(sumLng / _storyPoints.length, sumLat / _storyPoints.length));

    // Animăm secvențial apariția punctelor și liniilor dintre ele
    for (var i = 0; i < _storyPoints.length; i++) {
        // ✅ CHECK Pauză
        while (_isPaused) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;
        }

        if (!mounted) return;
        HapticFeedback.lightImpact();

        // Punct presiune (circle)
        await _popPlayer.stop();
        await _popPlayer.play(AssetSource('sounds/recap_balloon_pop.mp3'));

        final currPoint = _storyPoints[i];

        await _circleAnnotationManager!.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: currPoint),
            circleColor: 0xFFFF6D00,
            circleRadius: 18.0,
            circleBlur: 0.8,
            circleOpacity: 0.8,
          )
        );

        drawnPositions.add(currPoint);

        // Linia neon — un singur obiect actualizat progresiv (scalabil pentru sute de puncte)
        if (drawnPositions.length > 1) {
          if (routeLine == null) {
            routeLine = await _polylineAnnotationManager!.create(
              PolylineAnnotationOptions(
                geometry: LineString(coordinates: List.of(drawnPositions)),
                lineColor: 0xFF00E676,
                lineWidth: 4.0,
                lineOpacity: 0.6,
                lineJoin: LineJoin.ROUND,
              ),
            );
          } else {
            routeLine.geometry = LineString(coordinates: List.of(drawnPositions));
            await _polylineAnnotationManager!.update(routeLine);
          }
        }

        // Ușoară mutare a camerei spre Punctul curent pentru a vizualiza ruta construindu-se (smooth pan)
        if (i > 0) {
            _mapboxMap!.flyTo(
              CameraOptions(center: Point(coordinates: currPoint), zoom: 14.5, pitch: 45),
              MapAnimationOptions(duration: (800 / _playbackSpeed).round()),
            );
        }

        // Pauză între noduri - scalată cu viteza
        await Future.delayed(Duration(milliseconds: (1000 / _playbackSpeed).round()));
    }

    // Pasul 3: După finalizare construire cu neon -> Zoom Out să vadă absolut toate destinațiile locale
    if (!mounted) return;
    setState(() => _currentStep = 3);
    
    _spinPlayer.seek(Duration.zero);
    _spinPlayer.setVolume(1.0);
    _spinPlayer.play(AssetSource('sounds/recap_wind.mp3'));
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: centerBox,
        zoom: 12.0, // Zoom out parțial pentru a prinde zona urbană/rutele, dar suficient de detaliat
        pitch: 20.0,
        bearing: 0.0,
      ),
      MapAnimationOptions(duration: (3000 / _playbackSpeed).round()),
    );
    
    // Stăm 2.5 secunde să admire rețeaua de drumuri din săptămână - scalat
    await Future.delayed(Duration(milliseconds: (2500 / _playbackSpeed).round()));

    // Pasul 4: Ultimul Zoom Out către Satelit/Space View
    if (!mounted) return;
    setState(() => _currentStep = 4);
    
    _spinPlayer.seek(Duration.zero);
    // Efect fonic diferențiat pentru ultimul zoom-out: vântul pare că se "stinge" jucând la un volum puțin mai mic
    _spinPlayer.setVolume(0.6);
    _spinPlayer.play(AssetSource('sounds/recap_wind.mp3'));
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: centerBox,
        zoom: 1.5,
        pitch: 0.0,
        bearing: 0.0,
      ),
      MapAnimationOptions(duration: (3500 / _playbackSpeed).round()),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Ne apropiem...';
      case 2: return 'Punctele tale de atracție';
      case 3: return 'O săptămână excelentă!';
      default: return 'Săptămâna ta...';
    }
  }

  String _getStepSub() {
    switch (_currentStep) {
      case 1: return 'Zburăm spre casa ta';
      case 2: return 'Acestea sunt zonele în care ai petrecut cel mai mult timp.';
      case 3: return 'Analizând toate destinațiile globale...';
      case 4: return 'Experiența spațială reluată.';
      default: return 'Sincronizare rută...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Deschis pt tema warm când harta încarcă
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Stil SATELLITE_STREETS ("gen foto" cum a fost cerut)
          MapWidget(
            key: const ValueKey('WeekReviewMap'),
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.SATELLITE_STREETS, // Tema SATELLITE pentru o experiență fotorealistă
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            ),

          // Interfață Story Overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
                      );
                    },
                  ),
                ),
                // UI: Speed & Share Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _SpeedToggle(
                          speed: 0.5,
                          isSelected: _playbackSpeed == 0.5,
                          onTap: () => _updatePlaybackSpeed(0.5),
                        ),
                        const SizedBox(width: 8),
                        _SpeedToggle(
                          speed: 1.0,
                          isSelected: _playbackSpeed == 1.0,
                          onTap: () => _updatePlaybackSpeed(1.0),
                        ),
                        const SizedBox(width: 8),
                        _SpeedToggle(
                          speed: 2.0,
                          isSelected: _playbackSpeed == 2.0,
                          onTap: () => _updatePlaybackSpeed(2.0),
                        ),
                        const SizedBox(width: 16),
                        _ReplayButton(onTap: _replay),
                        const SizedBox(width: 8),
                        _CalendarButton(onTap: _openDateRangePicker),
                        const SizedBox(width: 16),
                        _DownloadButton(onTap: _saveReview),
                        const SizedBox(width: 8),
                        _ShareButton(onTap: _shareReview),
                      ],
                    ),
                  ),
                ),
                // Header (numele userului, datele, etc)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF7C3AED),
                              ),
                              child: Center(
                                child: Text(
                                  _userInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Nabour Review',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDateRange(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isPaused ? Icons.play_circle_fill_rounded : Icons.pause_circle_filled_rounded, 
                          color: Colors.white, 
                          size: 32,
                          shadows: const [Shadow(color: Colors.black45, blurRadius: 8)]
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Efecte text jos (dinamic, variază cu animatia)
                if (_isMapReady)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60, left: 24, right: 24),
                    child: AnimatedOpacity(
                      opacity: _currentStep >= 1 ? 1.0 : 0.0,
                      duration: const Duration(seconds: 1),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStepTitle(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getStepSub(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReview() async {
    if (_mapboxMap == null) return;
    
    HapticFeedback.mediumImpact();
    // Arătăm un mesaj de procesare
    _showPremiumToast('Generăm posterul pentru partajare...');

    try {
      // Facem un snapshot de hartă (Imagine de înaltă rezoluție)
      final Uint8List? snapshotBytes = await _mapboxMap?.snapshot();
      if (snapshotBytes == null) return;
      
      // Salvăm temporar fișierul pentru a-l putea partaja
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/nabour_recap_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(snapshotBytes);

      // Partajăm fișierul REAL folosind utilitarul proiectului
      await DeprecatedAPIsFix.shareFiles(
        [path],
        text: 'Uite cum a arătat săptămâna mea pe Nabour! 🚗✨ #NabourWeek',
        subject: 'Săptămâna mea Nabour',
      );
    } catch (e) {
      Logger.error('Error sharing week review: $e');
      _showPremiumToast('Eroare la partajare: $e');
    }
  }

  Future<void> _saveReview() async {
    if (_mapboxMap == null) return;
    HapticFeedback.mediumImpact();
    _showPremiumToast('Salvăm imaginea în galerie...');

    try {
      final Uint8List? snapshotBytes = await _mapboxMap?.snapshot();
      if (snapshotBytes == null) {
        _showPremiumToast('Eroare: nu s-a putut genera imaginea.');
        return;
      }

      // Scriem fișierul temporar și îl salvăm în galerie via gal
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/nabour_recap_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(snapshotBytes);

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putImage(path, album: 'Nabour');
      await file.delete();

      _showPremiumToast('Imagine salvată în galerie (albumul Nabour)!');
    } catch (e) {
      Logger.error('Error saving review to gallery: $e');
      _showPremiumToast('Eroare la salvare: $e');
    }
  }

  Future<void> _openDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _rangeFrom, end: _rangeTo),
      helpText: 'Selectează perioada pentru review',
      cancelText: 'ANULEAZĂ',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
              secondary: Color(0xFF7C3AED),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1A1A2E),
            ),
            scaffoldBackgroundColor: const Color(0xFF1A1A2E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    // Oprim animația curentă și resetăm
    _animTimer?.cancel();
    _progressController.stop();
    _progressController.reset();
    if (_circleAnnotationManager != null) await _circleAnnotationManager!.deleteAll();
    if (_polylineAnnotationManager != null) await _polylineAnnotationManager!.deleteAll();

    setState(() {
      _rangeFrom = picked.start;
      _rangeTo = picked.end;
      _currentStep = 0;
      _isPaused = false;
    });

    await _loadRealData();
  }

  String _formatDateRange() {
    String fmt(DateTime d) {
      final months = ['ian', 'feb', 'mar', 'apr', 'mai', 'iun', 'iul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      return '${d.day} ${months[d.month - 1]}';
    }
    return '${fmt(_rangeFrom)} – ${fmt(_rangeTo)}';
  }

  void _showPremiumToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SpeedToggle extends StatelessWidget {
  final double speed;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedToggle({
    required this.speed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade600 : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ReplayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReplayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: const Row(
          children: [
            Icon(Icons.replay_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'REPLAY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CalendarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'PERIOADĂ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DownloadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: const Row(
          children: [
            Icon(Icons.file_download_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.ios_share_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'SHARE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
