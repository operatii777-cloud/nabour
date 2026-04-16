import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/screens/ride_details_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/favorite_driver_button.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/core/skeletons/skeleton_ride_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  DateFilter _selectedFilter = DateFilter.all;

  UserRole? _userRole;
  bool _isLoadingRole = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    try {
      final role = await _firestoreService.getUserRole();
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoadingRole = false;
          if (role == UserRole.driver) {
            _tabController = TabController(length: 2, vsync: this);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRole = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingRole(e.toString())))
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String rideId, String destination) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmation),
        content: Text(l10n.deleteRideConfirmation(destination)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              
              try {
                await _firestoreService.deleteRide(rideId);
                if (navigator.mounted) navigator.pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.rideDeletedSuccess), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (navigator.mounted) navigator.pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.errorGeneric}: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterAll), 
              selected: _selectedFilter == DateFilter.all, 
              onSelected: (sel) => setState(() => _selectedFilter = DateFilter.all)
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterLastMonth), 
              selected: _selectedFilter == DateFilter.lastMonth, 
              onSelected: (sel) => setState(() => _selectedFilter = DateFilter.lastMonth)
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterLast3Months), 
              selected: _selectedFilter == DateFilter.last3Months, 
              onSelected: (sel) => setState(() => _selectedFilter = DateFilter.last3Months)
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterThisYear), 
              selected: _selectedFilter == DateFilter.thisYear, 
              onSelected: (sel) => setState(() => _selectedFilter = DateFilter.thisYear)
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView({required bool isDriver}) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Ride>>(
      stream: isDriver
          ? _firestoreService.getDriverRidesHistory(filter: _selectedFilter)
          : _firestoreService.getRidesHistory(filter: _selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const SkeletonRideCard(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorLoadingData,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.errorDetails(snapshot.error.toString()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noRidesInPeriod,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final rides = snapshot.data!;
        final locale = Localizations.localeOf(context);
        final dateFormat = DateFormat('dd MMM yyyy, HH:mm', locale.languageCode == 'en' ? 'en_US' : 'ro_RO');
        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            final formattedDate = dateFormat.format(ride.timestamp);
            final isCancelled = ride.wasCancelled;
            final textStyle = TextStyle(
              color: isCancelled ? Colors.red : null, 
              decoration: isCancelled ? TextDecoration.lineThrough : null
            );
            final iconColor = isCancelled ? Colors.red : Theme.of(context).colorScheme.primary;
            final costColor = isCancelled ? Colors.red : Colors.green.shade700;
            final icon = isCancelled ? Icons.cancel_outlined : Icons.directions_car;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(icon, color: iconColor, size: 40),
                title: Text(
                  l10n.rideToDestination(ride.destinationAddress), 
                  style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 15), 
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis
                ),
                subtitle: Text(l10n.rideDate(formattedDate), style: textStyle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Voluntar', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: costColor, 
                        fontSize: 15
                      )
                    ),
                    if (!isDriver && ride.driverId != null && ride.driverId!.isNotEmpty)
                      FavoriteDriverButton(driverId: ride.driverId!),
                    if (!isDriver) // Doar pasagerii pot șterge
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        tooltip: l10n.deleteRide,
                        onPressed: isCancelled ? null : () => _showDeleteConfirmationDialog(ride.id, ride.destinationAddress),
                      )
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => RideDetailsScreen(ride: ride))
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingRole) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.rideHistory)),
        body: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => const SkeletonRideCard(),
        ),
      );
    }

    if (_userRole == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.rideHistory)),
        body: Center(
          child: Text(l10n.errorLoadingUserRole),
        ),
      );
    }

    if (_userRole == UserRole.driver) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.rideHistory),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.asDriver),
              Tab(text: l10n.asPassenger),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                _buildFilterChips(),
                const Divider(height: 1),
                Expanded(child: _buildHistoryView(isDriver: true)),
              ],
            ),
            Column(
              children: [
                _buildFilterChips(),
                const Divider(height: 1),
                Expanded(child: _buildHistoryView(isDriver: false)),
              ],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.rideHistory)),
        body: Column(
          children: [
            _buildFilterChips(),
            const Divider(height: 1),
            Expanded(child: _buildHistoryView(isDriver: false)),
          ],
        ),
      );
    }
  }
}