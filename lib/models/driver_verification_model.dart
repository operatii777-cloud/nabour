import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model pentru verificarea șoferului (Uber-like)
enum VerificationStatus {
  pending,    // În așteptare
  verified,   // Verificat
  rejected,   // Respins
  expired,    // Expirat
}

enum VerificationType {
  identity,      // Verificare identitate
  license,       // Verificare permis
  vehicle,       // Verificare vehicul
  background,    // Background check
  insurance,     // Asigurare
}

class DriverVerification {
  final String id;
  final String driverId;
  final VerificationType type;
  final VerificationStatus status;
  final Timestamp? verifiedAt;
  final Timestamp? expiresAt;
  final String? verifiedBy; // Admin ID
  final String? notes;
  final Map<String, dynamic>? metadata;

  const DriverVerification({
    required this.id,
    required this.driverId,
    required this.type,
    required this.status,
    this.verifiedAt,
    this.expiresAt,
    this.verifiedBy,
    this.notes,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'type': type.name,
      'status': status.name,
      if (verifiedAt != null) 'verifiedAt': verifiedAt,
      if (expiresAt != null) 'expiresAt': expiresAt,
      if (verifiedBy != null) 'verifiedBy': verifiedBy,
      if (notes != null) 'notes': notes,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory DriverVerification.fromMap(Map<String, dynamic> map) {
    return DriverVerification(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      type: VerificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'identity'),
        orElse: () => VerificationType.identity,
      ),
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => VerificationStatus.pending,
      ),
      verifiedAt: map['verifiedAt'],
      expiresAt: map['expiresAt'],
      verifiedBy: map['verifiedBy'],
      notes: map['notes'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  bool get isVerified => status == VerificationStatus.verified;
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.toDate());
  }
}

/// Badge-uri de verificare pentru șoferi
class DriverVerificationBadge {
  final VerificationType type;
  final VerificationStatus status;
  final String label;
  final IconData icon;
  final Color color;

  const DriverVerificationBadge({
    required this.type,
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
  });

  static DriverVerificationBadge fromVerification(DriverVerification verification) {
    switch (verification.type) {
      case VerificationType.identity:
        return DriverVerificationBadge(
          type: verification.type,
          status: verification.status,
          label: 'Identitate Verificată',
          icon: Icons.verified_user,
          color: verification.isVerified ? Colors.green : Colors.grey,
        );
      case VerificationType.license:
        return DriverVerificationBadge(
          type: verification.type,
          status: verification.status,
          label: 'Permis Verificat',
          icon: Icons.credit_card,
          color: verification.isVerified ? Colors.blue : Colors.grey,
        );
      case VerificationType.vehicle:
        return DriverVerificationBadge(
          type: verification.type,
          status: verification.status,
          label: 'Vehicul Verificat',
          icon: Icons.directions_car,
          color: verification.isVerified ? Colors.orange : Colors.grey,
        );
      case VerificationType.background:
        return DriverVerificationBadge(
          type: verification.type,
          status: verification.status,
          label: 'Background Check',
          icon: Icons.security,
          color: verification.isVerified ? Colors.purple : Colors.grey,
        );
      case VerificationType.insurance:
        return DriverVerificationBadge(
          type: verification.type,
          status: verification.status,
          label: 'Asigurare Validă',
          icon: Icons.shield,
          color: verification.isVerified ? Colors.teal : Colors.grey,
        );
    }
  }
}

