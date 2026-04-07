import 'package:flutter/services.dart';

/// Serviciu centralizat pentru feedback haptic.
/// Folosit în toată aplicația prin HapticService.instance.*
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  /// Vibrație ușoară — tap pe buton, confirmare minoră
  Future<void> light() => HapticFeedback.lightImpact();

  /// Vibrație medie — selecție categorie, toggle switch
  Future<void> medium() => HapticFeedback.mediumImpact();

  /// Vibrație puternică — acceptare cursă (șofer), booking confirmat
  Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Succes — cursă finalizată, rating trimis, voucher aplicat
  Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Eroare — plată eșuată, acțiune invalidă
  Future<void> error() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  /// SOS / urgență — vibrație continuă 5 impulsuri puternice
  Future<void> sos() async {
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  /// Notificare nouă — puls dublu
  Future<void> notification() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
  }
}
