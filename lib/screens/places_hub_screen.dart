import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:nabour_app/features/smart_places/smart_places_db.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/favorite_addresses_screen.dart';
import 'package:nabour_app/theme/theme_provider.dart';
import 'package:nabour_app/utils/mapbox_utils.dart';
import 'package:nabour_app/widgets/app_drawer.dart';
import 'package:nabour_app/config/nabour_map_styles.dart';

/// Hub Locuri: învățate local, favorite, recomandări — polish tip Bump / Places.
class PlacesHubScreen extends StatefulWidget {
  const PlacesHubScreen({super.key});

  @override
  State<PlacesHubScreen> createState() => _PlacesHubScreenState();
}

class _PlacesHubScreenState extends State<PlacesHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LearnedPlace> _learned = [];
  bool _loadingLearned = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLearned();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLearned() async {
    setState(() => _loadingLearned = true);
    final list = await SmartPlacesDb.instance.getLearnedPlaces();
    if (!mounted) return;
    setState(() {
      _learned = list;
      _loadingLearned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drawerMenuPlaces),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.placesHubTabLearned),
            Tab(text: l10n.placesHubTabFavorites),
            Tab(text: l10n.placesHubTabRecommendations),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLearnedTab(theme),
          _buildFavoritesTab(theme),
          _buildRecommendationsTab(theme),
        ],
      ),
    );
  }

  Widget _buildLearnedTab(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_loadingLearned) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_learned.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.placesHubNoLearnedPlaces,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadLearned,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _learned.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final pl = _learned[i];
          final label = pl.label ??
              pl.kind ??
              l10n.placesHubFrequentArea(pl.dwellMinutes);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.place_rounded,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(label),
            subtitle: Text(
              l10n.placesHubVisitsConfidence(
                pl.visitCount,
                (pl.confidence * 100).round(),
              ),
            ),
            trailing: const Icon(Icons.map_rounded),
            onTap: () {
              final pt = MapboxUtils.createPoint(pl.lat, pl.lng);
              _openMiniMap(context, pt);
            },
          );
        },
      ),
    );
  }

  void _openMiniMap(BuildContext context, Point center) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        maxChildSize: 0.85,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.placesHubPreviewTitle,
              style: Theme.of(ctx).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Consumer<ThemeProvider>(
                    builder: (context, tp, _) {
                      return MapWidget(
                        key: ValueKey(
                            '${center.coordinates.lat}_${center.coordinates.lng}'),
                        cameraOptions: CameraOptions(
                          center: center,
                          zoom: 14,
                        ),
                        styleUri: NabourMapStyles.uriForMainMap(
                          lowDataMode: AppDrawer.lowDataMode,
                          darkMode: tp.isDarkMode,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.placesHubFavoritesHint,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FavoriteAddressesScreen(),
              ),
            );
          },
          icon: const Icon(Icons.edit_location_alt_rounded),
          label: Text(l10n.placesHubManageFavoriteAddresses),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.explore_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.placesHubDiscoverNeighborhood,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.placesHubDiscoverNeighborhoodHint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.people_outline_rounded),
          title: Text(l10n.placesHubFriendsNearbyTitle),
          subtitle: Text(l10n.placesHubFriendsNearbySubtitle),
        ),
      ],
    );
  }
}
