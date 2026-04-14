import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/screens/driver_ride_details_screen.dart';
import 'package:nabour_app/screens/driver_daily_report_screen.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/driver_achievements_widget.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/utils/logger.dart';

// Enum pentru a gestiona starea filtrului listei
enum DriverListFilter { all, today }

Widget _completedRideListTrailing() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.favorite_rounded, color: Colors.pink.shade400, size: 20),
      const SizedBox(width: 4),
      Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 22),
    ],
  );
}

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  int _ridesToday = 0;
  String _averageRating = "N/A";
  bool _isGeneratingDailyReport = false;

  // Stări pentru a gestiona filtrarea și afișarea listei
  DriverListFilter _activeFilter = DriverListFilter.all;
  List<Ride> _allRides = []; // Stocăm toate cursele aici pentru a le putea filtra rapid

  // 🚀 DOAR PENTRU CURSA ACTIVĂ (Cursele în așteptare sunt acum pe hartă)
  Ride? _activeRide;
  StreamSubscription? _activeRideSubscription;
  StreamSubscription? _ridesHistorySubscription;
  bool _isDriverAvailable = false;

  // Feature: Driver hours limit — tracks online session time
  Timer? _sessionTimer;
  double _sessionHours = 0.0;
  static const double _warnHours = 8.0;
  static const double _maxHours = 10.0;
  bool _hasShownHoursWarning = false;

  @override
  void initState() {
    super.initState();
    
    // Ascultăm la stream-ul de curse finalizate
    _ridesHistorySubscription = _firestoreService.getDriverRidesHistory().listen((rides) {
      if (mounted) {
        setState(() {
          _allRides = rides;
          _calculateStats(rides);
        });
      }
    });

    // 🚀 INIȚIALIZĂM DOAR SISTEMUL PENTRU CURSA ACTIVĂ
    _initializeDriverSystem();
    
    // Feature: Driver hours limit — start session timer check
    _startSessionHoursCheck();
  }
  
  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    _ridesHistorySubscription?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  // 🚀 FUNCȚIE SIMPLIFICATĂ - Doar pentru cursa activă
  Future<void> _initializeDriverSystem() async {
    try {
      // Verificăm disponibilitatea
      _isDriverAvailable = await _firestoreService.getDriverAvailability();
      
      // Ascultăm doar pentru cursa activă
      _listenForActiveRide();
      
      if (mounted) setState(() {});
    } catch (e) {
      Logger.error('Error initializing driver system: $e', tag: 'DASHBOARD', error: e);
    }
  }

  // Feature: Driver hours limit — periodically checks session duration
  void _startSessionHoursCheck() {
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (!mounted) return;
      final hours = await _firestoreService.getDriverSessionHours();
      if (!mounted) return;
      setState(() => _sessionHours = hours);

      if (hours >= _maxHours) {
        _forceDriverOffline();
      } else if (hours >= _warnHours && !_hasShownHoursWarning) {
        _hasShownHoursWarning = true;
        _showHoursWarningDialog(hours);
      }
    });

    // Also load initial value
    _firestoreService.getDriverSessionHours().then((hours) {
      if (mounted) setState(() => _sessionHours = hours);
    });
  }

  void _showHoursWarningDialog(double hours) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = _maxHours - hours;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.driverHoursLimit),
          ],
        ),
        content: Text(
          l10n.driverHoursWarningBody(hours.toStringAsFixed(1), remaining.toStringAsFixed(1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.confirmButton),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _setDriverOffline();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.goOffline, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _forceDriverOffline() async {
    final l10n = AppLocalizations.of(context)!;
    await _firestoreService.updateDriverAvailability(false);
    if (mounted) {
      setState(() => _isDriverAvailable = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.timer_off, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.driverHoursReachedLimitTitle),
            ],
          ),
          content: Text(l10n.driverHoursReachedLimitBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _setDriverOffline() async {
    await _firestoreService.updateDriverAvailability(false);
    if (mounted) setState(() => _isDriverAvailable = false);
  }

  // 🚀 FUNCȚIE PĂSTRATĂ - Ascultă pentru cursa activă
  void _listenForActiveRide() {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = _firestoreService
        .getActiveDriverRideStream()
        .listen(
          (ride) {
            Logger.debug('Active ride status: ${ride?.status}', tag: 'DASHBOARD');
            if (mounted) {
              setState(() {
                _activeRide = ride;
              });
            }
          },
          onError: (error) {
            Logger.error('Error listening for active ride: $error', tag: 'DASHBOARD', error: error);
            // Nu facem crash - doar logăm eroarea și continuăm cu null
            if (mounted) {
              setState(() {
                _activeRide = null;
              });
            }
          },
        );
  }

  void _calculateStats(List<Ride> rides) {
    int tempRidesCount = 0;
    double totalRating = 0;
    int ratingCount = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var ride in rides) {
      final rideDate = DateTime(ride.timestamp.year, ride.timestamp.month, ride.timestamp.day);

      if (rideDate.isAtSameMomentAs(today)) {
        tempRidesCount++;
      }

      if (ride.passengerRating != null) {
        totalRating += ride.passengerRating!;
        ratingCount++;
      }
    }

    if (mounted) {
      setState(() {
        _ridesToday = tempRidesCount;
        if (ratingCount > 0) {
          _averageRating = (totalRating / ratingCount).toStringAsFixed(2);
        }
      });
    }
  }

  Future<void> _generateDailyReport() async {
    setState(() {
      _isGeneratingDailyReport = true;
    });

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayRides = _allRides.where((ride) {
        return ride.timestamp.isAfter(startOfDay) && ride.timestamp.isBefore(endOfDay);
      }).toList();

      final l10n = AppLocalizations.of(context)!;
      
      if (todayRides.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noRidesTodayForReport),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ridesCompletedToday(todayRides.length)),
            backgroundColor: Colors.green,
          ),
        );
        _showReturnToMapDialog();
      }

    } catch (e) {
      if (mounted) {
        final l10nError = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nError.errorGeneratingReport(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingDailyReport = false;
        });
      }
    }
  }

  void _showReturnToMapDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.reportGenerated),
        content: Text(l10n.dailyReportGeneratedSuccess),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.stayHere),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text(l10n.goToMap),
          ),
        ],
      ),
    );
  }

  List<Ride> _getFilteredRides() {
    if (_activeFilter == DriverListFilter.today) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return _allRides.where((ride) {
        final rideDate = DateTime(ride.timestamp.year, ride.timestamp.month, ride.timestamp.day);
        return rideDate.isAtSameMomentAs(today);
      }).toList();
    }
    return _allRides;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredRides = _getFilteredRides();
    final listTitle = _activeFilter == DriverListFilter.today 
        ? l10n.completedRidesToday 
        : l10n.lastCompletedRides;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: l10n.goToMap,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                l10n.driverOptions,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(l10n.goToMap),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
            ListTile(
              leading: _isGeneratingDailyReport 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.today_outlined, color: Colors.green),
              title: Text(_isGeneratingDailyReport ? l10n.generatingReport : l10n.generateDailyReport),
              onTap: _isGeneratingDailyReport ? null : () {
                Navigator.pop(context);
                _generateDailyReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.blue),
              title: Text(l10n.driverMenuViewDailyReport),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverDailyReportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Feature: Driver hours limit — session hours banner
            if (_isDriverAvailable && _sessionHours > 0)
              _buildSessionHoursBanner(),
            _buildStatsSection(),
            const Divider(height: 1),
            
            // 🚀 SECȚIUNEA SIMPLIFICATĂ - Doar cursa activă sau status offline
            if (_activeRide != null)
              _buildActiveRideSection()
            else if (!_isDriverAvailable)
              _buildDriverOfflineSection()
            else
              _buildDriverOnlineSection(),
            
            const Divider(height: 1),
            
            // ✅ NOU: Tabel câștiguri pe săptămână
            if (_allRides.isNotEmpty) ...[
              _buildWeeklyEarningsTable(),
            ],
            
            // ✅ NOU: Achievements
            if (_allRides.isNotEmpty) ...[
              DriverAchievementsWidget(
                rides: _allRides,
                averageRating: double.tryParse(_averageRating) ?? 0.0,
              ),
            ],
            
              Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    listTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_activeFilter != DriverListFilter.all)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activeFilter = DriverListFilter.all;
                        });
                      },
                      child: Text(l10n.showAll),
                    )
                ],
              ),
            ),
            if (filteredRides.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(child: Text(l10n.noRidesMatchFilter)),
              )
            else
              ...filteredRides.take(10).map((ride) {
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('${l10n.to} ${ride.destinationAddress}'),
                  subtitle: Text(DateFormat('dd MMM, HH:mm').format(ride.timestamp)),
                  trailing: _completedRideListTrailing(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverRideDetailsScreen(ride: ride),
                      ),
                    );
                  },
                );
              }),
            if (filteredRides.length > 10)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    // Navigate to full history screen - to be implemented
                  },
                  child: Text(l10n.viewAllRides(filteredRides.length)),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 🚀 WIDGET PĂSTRAT - Afișează cursa activă
  Widget _buildActiveRideSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.drive_eta, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.activeRide,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.destination} ${_activeRide!.destinationAddress}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${_getRideStatusText(_activeRide!.status, l10n)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverRideDetailsScreen(ride: _activeRide!),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: Text(l10n.viewDetails),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 WIDGET PĂSTRAT - Șofer offline
  Widget _buildDriverOfflineSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.pause_circle_outline, color: Colors.grey.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.driverModeDeactivated,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.goToMapAndActivate,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            label: Text(l10n.goToMap),
          ),
        ],
      ),
    );
  }

  // 🚀 WIDGET NOU - Șofer online, fără cursă activă
  Widget _buildDriverOnlineSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.youAreAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.newRidesWillAppear,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            label: Text(l10n.goToMap),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 FUNCȚIE HELPER PĂSTRATĂ - Convertește status-ul în text citibil
  String _getRideStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'driver_found': return l10n.waitingForPassengerConfirmation;
      case 'accepted': return l10n.confirmedGoToPassenger;
      case 'arrived': return l10n.driverArrived;
      case 'in_progress': return l10n.rideInProgress;
      default: return status;
    }
  }

  /// Feature: Driver hours limit — shows a banner with session driving hours.
  Widget _buildSessionHoursBanner() {
    final l10n = AppLocalizations.of(context)!;
    final isWarning = _sessionHours >= _warnHours;
    final isCritical = _sessionHours >= _maxHours;
    final color = isCritical ? Colors.red : isWarning ? Colors.orange : Colors.green;
    final remaining = _maxHours - _sessionHours;

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(isCritical ? Icons.timer_off : Icons.timer, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCritical
                  ? l10n.driverSessionBannerCritical
                  : isWarning
                      ? l10n.driverSessionBannerWarning(_sessionHours.toStringAsFixed(1), remaining.toStringAsFixed(1))
                      : l10n.driverSessionBannerNormal(_sessionHours.toStringAsFixed(1)),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (isWarning)
            TextButton(
              onPressed: _setDriverOffline,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(l10n.goOffline),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            l10n.helpToday,
            _ridesToday.toString(),
            Icons.favorite_border,
            onTap: () {
              setState(() {
                _activeFilter = DriverListFilter.today;
              });
            },
          ),
          _buildStatCard(
            l10n.tokens,
            _ridesToday.toString(), // 1 token per ride
            Icons.generating_tokens_outlined,
            onTap: () {
              setState(() {
                _activeFilter = DriverListFilter.today;
              });
            },
          ),
          _buildStatCard(l10n.averageRatingShort, _averageRating, Icons.star_border_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _weeklyKudosStars(int count) {
    if (count <= 0) {
      return Text(
        '—',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    final show = count > 5 ? 5 : count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ...List.generate(
          show,
          (_) => Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
          ),
        ),
        if (count > 5)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '+',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.amber.shade900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyEarningsTable() {
    final l10n = AppLocalizations.of(context)!;
    final weeklyCounts = _calculateWeeklyRideCounts();
    final int totalRides = weeklyCounts.values.fold(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.driverDashboardWeeklyActivityTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Zi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      l10n.driverDashboardWeeklyKudosHeader,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              ...weeklyCounts.entries.map((entry) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _weeklyKudosStars(entry.value),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.driverDashboardWeeklyTotalHelpsWeek,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalRides',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.favorite_rounded,
                      color: Colors.pink.shade400,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateWeeklyRideCounts() {
    final Map<String, int> weeklyData = {};
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysSinceMonday));

    final daysOfWeek = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
    for (int i = 0; i < 7; i++) {
      weeklyData[daysOfWeek[i]] = 0;
    }

    for (var ride in _allRides) {
      final rideDate = DateTime(ride.timestamp.year, ride.timestamp.month, ride.timestamp.day);
      final daysDiff = rideDate.difference(monday).inDays;

      if (daysDiff >= 0 && daysDiff < 7) {
        final dayName = daysOfWeek[daysDiff];
        weeklyData[dayName] = (weeklyData[dayName] ?? 0) + 1;
      }
    }

    return weeklyData;
  }
}