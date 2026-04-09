import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/models/neighborhood_request_model.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:nabour_app/utils/logger.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class NeighborhoodRequestsManager {
  final MapboxMap mapboxMap;
  final BuildContext context;
  final VoidCallback onDataChanged;

  PointAnnotationManager? _annotationManager;
  /// Pinuri fly-to (căutare hartă, drop din chat) — separat de [ _annotationManager ],
  /// altfel [ _updateMapAnnotations ] face `deleteAll` și șterge pinul imediat.
  PointAnnotationManager? _transientPinManager;
  PointAnnotation? _lastTransientPin;
  Timer? _transientPinExpiryTimer;
  StreamSubscription<List<NeighborhoodRequest>>? _subscription;
  Timer? _evaporationTimer;

  final Map<String, NeighborhoodRequest> _activeRequests = {};
  final Map<String, String> _annotationIdToRequestId = {};

  NeighborhoodRequestsManager({
    required this.mapboxMap,
    required this.context,
    required this.onDataChanged,
  });

  /// Înainte de [initialize] (inclusiv a doua oară după `_onStyleLoaded`): eliberăm id-urile
  /// fixe de manager, altfel `createPointAnnotationManager` poate eșua sau rămâne Dart valid
  /// dar fără randare după mutații de stil (vezi `map_screen` / GPU).
  Future<void> _prepareForReinitialize() async {
    _transientPinExpiryTimer?.cancel();
    _transientPinExpiryTimer = null;
    _lastTransientPin = null;

    _subscription?.cancel();
    _subscription = null;

    _evaporationTimer?.cancel();
    _evaporationTimer = null;

    if (_transientPinManager != null) {
      try {
        await _transientPinManager!.deleteAll();
        mapboxMap.annotations.removeAnnotationManagerById('map-transient-pins-layer');
      } catch (_) {}
      _transientPinManager = null;
    }
    if (_annotationManager != null) {
      try {
        await _annotationManager!.deleteAll();
        mapboxMap.annotations.removeAnnotationManagerById('neighborhood-requests-layer');
      } catch (_) {}
      _annotationManager = null;
    }
  }

  Future<void> initialize() async {
    try {
      await _prepareForReinitialize();

      _annotationManager = await mapboxMap.annotations.createPointAnnotationManager(id: 'neighborhood-requests-layer');
      _annotationManager?.tapEvents(onTap: _onAnnotationTapped);

      _transientPinManager =
          await mapboxMap.annotations.createPointAnnotationManager(id: 'map-transient-pins-layer');

      _subscription = FirestoreService().getActiveNeighborhoodRequests().listen(
        (requests) {
          _activeRequests.clear();
          for (var r in requests) {
            _activeRequests[r.id] = r;
          }
          _updateMapAnnotations();
          onDataChanged();
        },
        onError: (Object e, StackTrace st) {
          Logger.error('Neighborhood requests stream failed', error: e, stackTrace: st,
              tag: 'NeighborhoodRequests');
        },
      );

      // Timer: evaporare vizuală + eliminare locală după expirare (snapshot Firestore
      // nu se re-emite doar pentru trecerea timpului).
      _evaporationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        final now = DateTime.now();
        _activeRequests.removeWhere(
          (id, r) => r.expiresAt.isBefore(now) || r.resolved,
        );
        unawaited(_updateMapAnnotations());
        onDataChanged();
      });
    } catch (e) {
      Logger.error('NeighborhoodRequestsManager init failed', error: e,
          tag: 'NeighborhoodRequests');
    }
  }

  void dispose() {
    unawaited(_prepareForReinitialize());
  }

  Future<void> _updateMapAnnotations() async {
    if (_annotationManager == null) return;

    _annotationIdToRequestId.clear();
    await _annotationManager!.deleteAll();

    final entries = _activeRequests.values
        .where((r) => r.evaporationProgress > 0.05)
        .toList();
    if (entries.isEmpty) return;

    // Generare PNG în paralel — înainte era secvențială și îngheța UI la multe cereri active.
    final icons = await Future.wait(
      entries.map(
        (request) => _buildRequestChatBubbleBitmap(
          request,
          request.evaporationProgress,
        ),
      ),
    );

    for (var i = 0; i < entries.length; i++) {
      final request = entries[i];
      final progress = request.evaporationProgress;
      final icon = icons[i];

      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(request.lng, request.lat)),
        image: icon,
        iconSize: (0.38 + 0.12 * progress).clamp(0.34, 0.52),
        iconOpacity: progress,
        iconAnchor: IconAnchor.CENTER,
      );

      try {
        final annotation = await _annotationManager!.create(options);
        _annotationIdToRequestId[annotation.id] = request.id;
      } catch (_) {}
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'ride': return Colors.purple;
      case 'help': return Colors.green;
      case 'tool': return Colors.orange;
      case 'alert': return Colors.red;
      default: return Colors.blue;
    }
  }

  String _emojiForRequestType(String type) {
    switch (type) {
      case 'ride':
        return '🚗';
      case 'help':
        return '🛠️';
      case 'tool':
        return '🔧';
      case 'alert':
        return '🚨';
      default:
        return '💬';
    }
  }

  /// Balon subțire tip mesaj (emoji la început + text), ca să nu acopere vecinii pe hartă.
  Future<Uint8List> _buildRequestChatBubbleBitmap(
    NeighborhoodRequest request,
    double progress,
  ) async {
    final accent = _getColorForType(request.type);
    final emoji = _emojiForRequestType(request.type);
    const double maxTextWidth = 188;
    const double padH = 10;
    const double emojiSlot = 28;
    const double gap = 6;
    const double radius = 14;

    final messagePainter = painting.TextPainter(
      text: painting.TextSpan(
        text: request.message.replaceAll('\n', ' ').trim(),
        style: painting.TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1E).withValues(alpha: progress),
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: painting.TextDirection.ltr,
    )..layout(maxWidth: maxTextWidth);

    final textW = messagePainter.width;
    final totalW =
        (padH + emojiSlot + gap + textW + padH).clamp(112.0, 248.0);
    final totalH = 40.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, totalW, totalH));

    final bg = ui.Paint()
      ..color = const Color(0xFFF8F9FC).withValues(alpha: 0.97 * progress);
    final border = ui.Paint()
      ..color = accent.withValues(alpha: 0.85 * progress)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final shadow = ui.Paint()
      ..color = const Color(0x28000000).withValues(alpha: progress)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);

    final rrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0.5, 0.5, totalW - 1, totalH - 1),
      const ui.Radius.circular(radius),
    );
    final shadowRrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0.5, 1.8, totalW - 1, totalH - 1),
      const ui.Radius.circular(radius),
    );
    canvas.drawRRect(shadowRrect, shadow);
    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(rrect, border);

    final emojiPara = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 18,
      textAlign: ui.TextAlign.center,
    ))
      ..addText(emoji);
    final ep = emojiPara.build();
    ep.layout(ui.ParagraphConstraints(width: emojiSlot + 4));
    canvas.drawParagraph(
      ep,
      ui.Offset(padH - 2, (totalH - ep.height) / 2),
    );

    messagePainter.paint(
      canvas,
      ui.Offset(padH + emojiSlot + gap, (totalH - messagePainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      totalW.ceil(),
      totalH.ceil(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onAnnotationTapped(PointAnnotation annotation) {
    final requestId = _annotationIdToRequestId[annotation.id];
    if (requestId != null) {
      final request = _activeRequests[requestId];
      if (request != null) {
        _showMicroBiddingSheet(request);
      }
    }
  }

  /// Pin după fly-to (căutare universală pe hartă, locație din chat).
  Future<void> showTransientLocationPin(double lat, double lng) async {
    if (_transientPinManager == null) {
      Logger.warning(
        'showTransientLocationPin: no transient manager (init not done or style rebuild)',
        tag: 'NeighborhoodRequests',
      );
      return;
    }

    _transientPinExpiryTimer?.cancel();

    if (_lastTransientPin != null) {
      try {
        await _transientPinManager!.delete(_lastTransientPin!);
      } catch (_) {}
      _lastTransientPin = null;
    }

    // Generăm un icon roșu pulsativ (simplificat aici ca un cerc roșu dublu)
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final pulsePaint = ui.Paint()
      ..color = Colors.red.withValues(alpha: 0.4)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(const Offset(50, 50), 45, pulsePaint);

    final pinPaint = ui.Paint()
      ..color = Colors.red
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(const Offset(50, 50), 20, pinPaint);

    final borderPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(const Offset(50, 50), 20, borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = byteData!.buffer.asUint8List();

    final options = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)),
      image: icon,
      iconSize: 1.2,
      iconAnchor: IconAnchor.CENTER,
    );

    try {
      final annotation = await _transientPinManager!.create(options);
      _lastTransientPin = annotation;
      final toExpire = annotation;
      Logger.debug(
        'Transient fly-to pin created at $lat,$lng',
        tag: 'NeighborhoodRequests',
      );
      _transientPinExpiryTimer = Timer(const Duration(seconds: 15), () {
        try {
          _transientPinManager?.delete(toExpire);
          if (_lastTransientPin?.id == toExpire.id) {
            _lastTransientPin = null;
          }
        } catch (_) {}
      });
    } catch (e) {
      Logger.warning('Transient map pin failed: $e', tag: 'NeighborhoodRequests');
    }
  }

  // GLASSMORPHISM MICRO-BIDDING UI
  void _showMicroBiddingSheet(NeighborhoodRequest request) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isAuthor = myUid != null && myUid == request.authorUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Pentru efectul de sticlă
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getColorForType(request.type).withValues(alpha: 0.2),
                    child: Icon(Icons.person, color: _getColorForType(request.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(
                          isAuthor
                              ? 'Cererea ta pe hartă (se evaporă automat la expirare)'
                              : 'Timp rămas: ${request.expiresAt.difference(DateTime.now()).inMinutes.clamp(0, 999)} min',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                request.message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              if (isAuthor) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade800,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Ștergi cererea?'),
                          content: const Text(
                            'Dispare imediat de pe hartă pentru toată lumea. Poți publica alta oricând.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Nu'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text('Șterge', style: TextStyle(color: Colors.red.shade800)),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !ctx.mounted) return;
              
                      try {
                        await FirestoreService().deleteNeighborhoodRequest(request.id);
                        _activeRequests.remove(request.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        unawaited(_updateMapAnnotations());
                        onDataChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cererea a fost ștearsă de pe hartă.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nu s-a putut șterge: $e'),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Șterge cererea de pe hartă', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const Text('Răspunde rapid:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBiddingChip(ctx, 'Rezolv acum! 🚀', Colors.green, request),
                    _buildBiddingChip(ctx, 'Te costă o cafea ☕', Colors.orange, request),
                    _buildBiddingChip(ctx, 'Ajut, dar mă grăbesc ⏱️', Colors.blue, request),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Închide', style: TextStyle(color: Colors.grey)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildBiddingChip(
      BuildContext sheetContext, String text, Color color, NeighborhoodRequest request) {
    return ActionChip(
      label: Text(text, style: TextStyle(color: color.withValues(alpha: 0.9), fontWeight: FontWeight.bold)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        Navigator.pop(sheetContext);
        final navContext = context;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_handleNeighborhoodBidResponse(navContext, request, text));
        });
      },
    );
  }

  /// Marchează cererea rezolvată, trimite un mesaj inițial în chat privat cu autorul și deschide [ChatScreen].
  Future<void> _handleNeighborhoodBidResponse(
    BuildContext navContext,
    NeighborhoodRequest request,
    String chipLabel,
  ) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirestoreService().resolveNeighborhoodRequest(request.id);
    } catch (e) {
      Logger.warning('resolveNeighborhoodRequest: $e', tag: 'NeighborhoodRequests');
    }
    onDataChanged();

    if (!navContext.mounted) return;

    if (myUid == null) {
      ScaffoldMessenger.of(navContext).showSnackBar(
        const SnackBar(content: Text('Cererea a fost marcată rezolvată. Autentifică-te pentru chat.')),
      );
      return;
    }

    final authorUid = request.authorUid;
    final invalidAuthor =
        authorUid.isEmpty || authorUid == 'anon' || authorUid == myUid;

    if (invalidAuthor) {
      ScaffoldMessenger.of(navContext).showSnackBar(
        SnackBar(content: Text('Cerere rezolvată. ${request.authorName}')),
      );
      return;
    }

    final sorted = [myUid, authorUid]..sort();
    final roomId = sorted.join('_');
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Un vecin';
    final opener =
        '$chipLabel\n\nReferitor la: „${request.message}”';

    try {
      await FirebaseFirestore.instance
          .collection('private_chats')
          .doc(roomId)
          .collection('messages')
          .add({
        'text': opener,
        'senderId': myUid,
        'senderName': myName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.warning('Neighborhood bid → private_chats: $e', tag: 'NeighborhoodRequests');
      if (navContext.mounted) {
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text('Cerere rezolvată, dar mesajul nu s-a trimis: $e'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }

    if (!navContext.mounted) return;

    ScaffoldMessenger.of(navContext).showSnackBar(
      SnackBar(
        content: Text('Deschidem chat cu ${request.authorName}…'),
        duration: const Duration(seconds: 2),
      ),
    );

    await Navigator.push<void>(
      navContext,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          rideId: roomId,
          otherUserId: authorUid,
          otherUserName: request.authorName,
          collectionName: 'private_chats',
        ),
      ),
    );
  }

  // CREATE NEW REQUEST BOTTOM SHEET
  /// [lat]/[lng] — unde apare bula (GPS-ul tău sau poziția unui contact de pe hartă).
  /// [initialMessage] / [locationContext] — opțional, ex. când deschizi din profilul unui vecin.
  static void showCreateRequestSheet(
    BuildContext context,
    double lat,
    double lng, {
    String? initialMessage,
    String? locationContext,
  }) {
    final TextEditingController messageController =
        TextEditingController(text: initialMessage ?? '');
    String selectedType = 'ride';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16, right: 16, top: 24
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30),
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Aruncă o cerere pe hartă 💧',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Închide',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locationContext ??
                        'Cererea ta va fi vizibilă pentru vecini și se va evapora automat într-o oră.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  // Category Selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategorySelect('🚗 Cursă', 'ride', selectedType, (v) => setState(() => selectedType = v)),
                        _buildCategorySelect('🛠️ Ajutor', 'help', selectedType, (v) => setState(() => selectedType = v)),
                        _buildCategorySelect('🔧 Scule', 'tool', selectedType, (v) => setState(() => selectedType = v)),
                        _buildCategorySelect('🚨 Alertă', 'alert', selectedType, (v) => setState(() => selectedType = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ex: Merg spre centru, are cineva loc?',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        if (messageController.text.trim().isEmpty) return;

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Autentifică-te ca să lași o cerere pe hartă.'),
                            ),
                          );
                          return;
                        }

                        final authorName = user.displayName?.trim();
                        final resolvedName = (authorName != null && authorName.isNotEmpty)
                            ? authorName
                            : 'Vecin';

                        final req = NeighborhoodRequest(
                          id: const Uuid().v4(),
                          authorUid: user.uid,
                          authorName: resolvedName,
                          type: selectedType,
                          message: messageController.text.trim(),
                          lat: lat,
                          lng: lng,
                          createdAt: DateTime.now(),
                          expiresAt: DateTime.now().add(const Duration(hours: 1)),
                        );

                        // Închidem foaia imediat; așteptarea rețelei înainte de pop făcea acțiunea „înghețată”.
                        Navigator.pop(ctx);

                        try {
                          await FirestoreService().createNeighborhoodRequest(req);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bula de cerere a fost lăsată pe hartă! 🫧'),
                            ),
                          );
                        } catch (e) {
                          Logger.error('createNeighborhoodRequest failed', error: e,
                              tag: 'NeighborhoodRequests');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Nu am putut publica cererea. Ești online? ${e is FirebaseException ? e.message ?? '' : e}',
                              ),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                        }
                      },
                      child: const Text('Lansează Bula 🫧', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  static Widget _buildCategorySelect(String label, String value, String selectedValue, Function(String) onSelect) {
    final isSelected = value == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(value),
        selectedColor: Colors.indigo.withValues(alpha: 0.2),
        checkmarkColor: Colors.indigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
