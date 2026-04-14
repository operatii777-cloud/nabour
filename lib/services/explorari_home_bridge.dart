import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:nabour_app/utils/logger.dart';

/// Actualizează widget-ul nativ Android „Explorări”. Pe iOS adaugă App Group + extensie în Xcode.
Future<void> updateExplorariHomeWidget({
  required int tileCount,
  required int percentRounded,
}) async {
  if (kIsWeb) return;
  try {
    await HomeWidget.saveWidgetData<String>('explorari_tiles', '$tileCount');
    await HomeWidget.saveWidgetData<String>('explorari_pct', '$percentRounded');
    await HomeWidget.updateWidget(
      // Același nume de clasă ca înainte — widget-urile deja pe ecran rămân valide după update.
      qualifiedAndroidName: 'com.florin.nabour.ScratchMapWidgetProvider',
    );
  } catch (e) {
    Logger.warning('HomeWidget explorări: $e', tag: 'WIDGET');
  }
}
