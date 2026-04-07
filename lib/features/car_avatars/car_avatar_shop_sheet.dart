import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_service.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// După garaj: [appliedIdsBySlot] — sloturile tocmai salvate (optimistic pe hartă pentru slotul activ).
/// [selected] + [editedSlot] pentru fluxul vechi (ex. cumpărare imediată).
typedef CarGarageInventoryCallback = void Function([
  CarAvatar? selected,
  CarAvatarMapSlot? editedSlot,
  Map<CarAvatarMapSlot, String>? appliedIdsBySlot,
]);

class CarAvatarShopSheet extends StatefulWidget {
  const CarAvatarShopSheet({super.key, this.onInventoryChanged});

  /// După cumpărare: [selected] + [editedSlot].
  /// După **Aplică**: doar [appliedIdsBySlot] cu sloturile modificate.
  /// La închiderea sheet-ului: fără argumente → reîncarcă din Firestore.
  final CarGarageInventoryCallback? onInventoryChanged;

  @override
  State<CarAvatarShopSheet> createState() => _CarAvatarShopSheetState();

  static Future<void> show(
    BuildContext context, {
    CarGarageInventoryCallback? onClosed,
  }) {
    var didNotify = false;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CarAvatarShopSheet(
        onInventoryChanged: ([CarAvatar? a, CarAvatarMapSlot? slot, Map<CarAvatarMapSlot, String>? batch]) {
          didNotify = true;
          onClosed?.call(a, slot, batch);
        },
      ),
    ).whenComplete(() {
      // Fără al doilea apel după selectare: evită dubla _loadCustomCarAvatar (cache clear + PNG).
      if (!didNotify) {
        onClosed?.call();
      }
    });
  }
}

class _CarAvatarShopSheetState extends State<CarAvatarShopSheet> {
  final CarAvatarService _avatarService = CarAvatarService();
  final TokenService _tokenService = TokenService();
  
  List<CarAvatar> _avatars = [];
  Set<String> _purchasedIds = {};
  String _selectedDriverId = 'default_car';
  String _selectedPassengerId = 'default_car';
  /// Alegeri locale până la **Aplică** (nu scriu în Firestore).
  String _draftDriverId = 'default_car';
  String _draftPassengerId = 'default_car';
  CarAvatarMapSlot _mapSlot = CarAvatarMapSlot.driver;
  int _userTokens = 0;
  bool _isLoading = true;
  bool _applyInFlight = false;
  CarCategory _selectedCategory = CarCategory.transport;

  String get _activeSlotDraftId =>
      _mapSlot == CarAvatarMapSlot.driver ? _draftDriverId : _draftPassengerId;

  bool get _hasUnappliedChanges =>
      _draftDriverId != _selectedDriverId || _draftPassengerId != _selectedPassengerId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final avatars = _avatarService.getAvailableAvatars();
      final purchased = await _avatarService.getPurchasedAvatarIds();
      final driverSel =
          await _avatarService.getSelectedAvatarIdForSlot(CarAvatarMapSlot.driver);
      final passengerSel =
          await _avatarService.getSelectedAvatarIdForSlot(CarAvatarMapSlot.passenger);
      final tokens = await _tokenService.getTokenBalance();

      if (mounted) {
        setState(() {
          _avatars = avatars;
          _purchasedIds = purchased;
          if (driverSel != 'default_car') _purchasedIds.add(driverSel);
          if (passengerSel != 'default_car') _purchasedIds.add(passengerSel);
          _selectedDriverId = driverSel;
          _selectedPassengerId = passengerSel;
          _draftDriverId = driverSel;
          _draftPassengerId = passengerSel;
          _userTokens = tokens;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading shop data: $e');
      if (mounted) {
        var fd = 'default_car';
        var fp = 'default_car';
        try {
          fd = await _avatarService.getSelectedAvatarIdForSlot(CarAvatarMapSlot.driver);
          fp = await _avatarService.getSelectedAvatarIdForSlot(CarAvatarMapSlot.passenger);
        } catch (_) {}
        setState(() {
          _avatars = _avatarService.getAvailableAvatars();
          _purchasedIds = {
            'default_car',
            if (fd != 'default_car') fd,
            if (fp != 'default_car') fp,
          };
          _selectedDriverId = fd;
          _selectedPassengerId = fp;
          _draftDriverId = fd;
          _draftPassengerId = fp;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePurchase(CarAvatar avatar) async {
    if (_mapSlot == CarAvatarMapSlot.driver && !avatar.allowsDriverMapSlot) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Text(
            'Nu poți aplica acest personaj la volan — doar ca pasager. Comută pe „CA PASAGER”.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    if (_mapSlot == CarAvatarMapSlot.passenger && !avatar.allowsPassengerMapSlot) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Text(
            'Salupa e doar pentru la volan (șofer). Comută pe „LA VOLAN” sau alege alt vehicul pentru pasager.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    final wallet = await _tokenService.getWallet();
    if (!mounted) return;
    final unlimited = wallet?.isUnlimited ?? false;
    if (!unlimited && _userTokens < avatar.price) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Nu ai suficienți tokeni! 🪙'), backgroundColor: Colors.red),
      );
      return;
    }

    final success =
        await _avatarService.purchaseAvatar(avatar, applyToSlot: _mapSlot);
    if (success) {
      if (mounted) {
        setState(() {
          _purchasedIds.add(avatar.id);
          if (_mapSlot == CarAvatarMapSlot.driver) {
            _selectedDriverId = avatar.id;
            _draftDriverId = avatar.id;
          } else {
            _selectedPassengerId = avatar.id;
            _draftPassengerId = avatar.id;
          }
        });
      }
      // După frame: evită crash/ANR din reentrare Mapbox + modal garaj.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          widget.onInventoryChanged?.call(avatar, _mapSlot, null);
        } catch (e, st) {
          Logger.error('Garaj → hartă (după cumpărare): $e', error: e, stackTrace: st);
        }
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Felicitări! Ai deblocat ${avatar.name}! 🚀'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            unlimited
                ? 'Nu s-a putut finaliza cumpărarea (rețea sau reguli). Încearcă din nou.'
                : 'Cumpărarea a eșuat — verifică soldul sau conexiunea.',
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  void _pickDraftAvatar(String id) {
    final av = _avatarService.getAvatarById(id);
    if (_mapSlot == CarAvatarMapSlot.driver && !av.allowsDriverMapSlot) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Text(
            'Acest personaj e doar pentru pasager. Pentru la volan alege un vehicul din transport.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    if (_mapSlot == CarAvatarMapSlot.passenger && !av.allowsPassengerMapSlot) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Text(
            'Salupa se folosește doar ca șofer (la volan), nu ca pasager pe hartă.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    setState(() {
      if (_mapSlot == CarAvatarMapSlot.driver) {
        _draftDriverId = id;
      } else {
        _draftPassengerId = id;
      }
    });
  }

  Future<void> _applyGarageSelection() async {
    if (!_hasUnappliedChanges || _applyInFlight) return;
    setState(() => _applyInFlight = true);
    final driverChanged = _draftDriverId != _selectedDriverId;
    final passengerChanged = _draftPassengerId != _selectedPassengerId;

    try {
      if (driverChanged) {
        final ok = await _avatarService.selectAvatarForSlot(
          _draftDriverId,
          CarAvatarMapSlot.driver,
        );
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: const Text(
                'Nu s-a putut salva mașina la volan. Verifică rețeaua sau App Check (mod debug).',
              ),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }
      if (passengerChanged) {
        final ok = await _avatarService.selectAvatarForSlot(
          _draftPassengerId,
          CarAvatarMapSlot.passenger,
        );
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: const Text(
                'Nu s-a putut salva mașina ca pasager. Verifică rețeaua sau App Check (mod debug).',
              ),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _selectedDriverId = _draftDriverId;
        _selectedPassengerId = _draftPassengerId;
      });

      final batch = <CarAvatarMapSlot, String>{};
      if (driverChanged) batch[CarAvatarMapSlot.driver] = _draftDriverId;
      if (passengerChanged) batch[CarAvatarMapSlot.passenger] = _draftPassengerId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          widget.onInventoryChanged?.call(null, null, batch);
        } catch (e, st) {
          Logger.error('Garaj → hartă (aplicare): $e', error: e, stackTrace: st);
        }
      });

      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: const Text('Modificările au fost aplicate pe profil și hartă.'),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applyInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.15,
                        colors: [
                          const Color(0xFF4C1D95).withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomRight,
                        radius: 1.0,
                        colors: [
                          const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildMapSlotSelector(),
                    const SizedBox(height: 20),
                    _buildSelectedPreview(),
                    const SizedBox(height: 24),
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    Expanded(child: _buildAvatarGrid()),
                    if (_hasUnappliedChanges) ...[
                      const SizedBox(height: 12),
                      _buildApplyBar(),
                    ] else
                      const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyBar() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _applyInFlight ? null : _applyGarageSelection,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: _applyInFlight
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
              )
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(
          _applyInFlight ? 'Se aplică…' : 'Aplică pe profil și hartă',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GALAXY GARAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Alege din listă, apoi Aplică — modificările merg pe profil și pe hartă.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 6),
              Text(
                '$_userTokens',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSlotSelector() {
    Widget chip(CarAvatarMapSlot slot, String label, IconData icon) {
      final on = _mapSlot == slot;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              _mapSlot = slot;
              if (slot == CarAvatarMapSlot.driver) {
                final d = _avatarService.getAvatarById(_draftDriverId);
                if (!d.allowsDriverMapSlot) {
                  _draftDriverId = 'default_car';
                }
              } else {
                final p = _avatarService.getAvatarById(_draftPassengerId);
                if (!p.allowsPassengerMapSlot) {
                  _draftPassengerId = 'default_car';
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: on ? Colors.amber.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: on ? Colors.amber : Colors.white12,
                width: on ? 2 : 1,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: on ? Colors.amber : Colors.white38),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: on ? Colors.amber : Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(CarAvatarMapSlot.driver, 'LA VOLAN', Icons.drive_eta_rounded),
        const SizedBox(width: 12),
        chip(CarAvatarMapSlot.passenger, 'CA PASAGER', Icons.person_rounded),
      ],
    );
  }

  /// Evită iconița Flutter „imagine lipsă” (X) când lipsește PNG-ul din bundle.
  Widget _carAvatarImage(String assetPath, {double? height, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      assetPath,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Icon(
        Icons.directions_car_filled_rounded,
        size: height != null ? (height * 0.55).clamp(28.0, 56.0) : 48,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CarCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          String label = cat.name.toUpperCase();
          IconData icon = Icons.directions_car_rounded;
          
          if (cat == CarCategory.animals) {
            label = 'ANIMĂLUȚE';
            icon = Icons.pets_rounded;
          } else if (cat == CarCategory.characters) {
            label = 'CARACTERE';
            icon = Icons.auto_awesome_rounded;
          } else {
            label = 'TRANSPORT';
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.amber : Colors.white10,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ] : [],
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: isSelected ? Colors.amber : Colors.white38),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedPreview() {
    final selected = _avatarService.getAvatarById(_activeSlotDraftId);
    final slotHint = _mapSlot == CarAvatarMapSlot.driver
        ? (_hasUnappliedChanges && _draftDriverId != _selectedDriverId
            ? 'Previzualizare — apasă Aplică pentru volan'
            : 'Pe hartă când ești șofer disponibil')
        : (_hasUnappliedChanges && _draftPassengerId != _selectedPassengerId
            ? 'Previzualizare — apasă Aplică pentru pasager'
            : 'Pe hartă ca pasager (sau șofer indisponibil)');
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
          ),
          _carAvatarImage(selected.assetPath, height: 100),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  slotHint,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid() {
    final filtered = _avatars
        .where(
          (a) =>
              a.category == _selectedCategory &&
              (_mapSlot != CarAvatarMapSlot.driver || a.allowsDriverMapSlot) &&
              (_mapSlot != CarAvatarMapSlot.passenger || a.allowsPassengerMapSlot),
        )
        .toList();

    if (filtered.isEmpty) {
      final driverNoVehicles = _mapSlot == CarAvatarMapSlot.driver &&
          _avatars.any((a) => a.category == _selectedCategory);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 48),
            const SizedBox(height: 12),
            Text(
              driverNoVehicles
                  ? 'La volan sunt doar vehicule (transport). Animalele și personajele sunt pentru pasager.'
                  : 'În curând în garaj...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontStyle: driverNoVehicles ? FontStyle.normal : FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final avatar = filtered[index];
          final isPurchased = _purchasedIds.contains(avatar.id);
          final isSelected = _activeSlotDraftId == avatar.id;
          final isCommittedForSlot = _mapSlot == CarAvatarMapSlot.driver
              ? _selectedDriverId == avatar.id
              : _selectedPassengerId == avatar.id;
          final isPendingApply = isSelected && isPurchased && !isCommittedForSlot;

          return GestureDetector(
            onTap: () {
              if (avatar.comingSoon) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text('${avatar.name} — desenele profesionale vin în curând în bundle. 🌌'),
                    backgroundColor: Colors.indigo.shade800,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              if (isPurchased) {
                _pickDraftAvatar(avatar.id);
              } else {
                _showConfirmPurchase(avatar);
              }
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Opacity(
                          opacity: avatar.comingSoon ? 0.45 : 1,
                          child: _carAvatarImage(avatar.assetPath, fit: BoxFit.contain),
                        ),
                      ),
                      if (avatar.comingSoon)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'ÎN CURÂND',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    avatar.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                if (avatar.comingSoon)
                  Text(
                    'Artă în curs',
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (isPurchased) ...[
                  Text(
                    isPendingApply
                        ? 'APASĂ APLICĂ'
                        : (isSelected ? 'SELECTAT' : 'DEBLOCAT'),
                    style: TextStyle(
                      color: isPendingApply
                          ? Colors.cyanAccent
                          : (isSelected ? Colors.amber : Colors.green),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.token, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${avatar.price}',
                        style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  void _showConfirmPurchase(CarAvatar avatar) {
    if (avatar.comingSoon) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Deblochează ${avatar.name}?', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Ești sigur că vrei să cheltuiești ${avatar.price} tokeni?\n'
          'Se aplică pentru ${_mapSlot == CarAvatarMapSlot.driver ? 'LA VOLAN' : 'CA PASAGER'}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handlePurchase(avatar);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Cumpără', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
