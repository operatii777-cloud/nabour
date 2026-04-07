import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/models/ride_model.dart';

enum UserRole { passenger, driver }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  // Profile Information
  final String? profileImageUrl;
  final String? age;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  
  // Driver Specific Fields
  final String? licensePlate;
  final String? driverCategory;
  final String? carMake;
  final String? carModel;
  final String? carColor;
  final String? carYear;
  final double? averageRating;
  final int? totalRides;
  final bool? isDriverActive;
  final String? driverApplicationStatus; // pending_review, approved, rejected
  final DateTime? driverApprovedAt;
  
  // Passenger Specific Fields
  final List<String> favoriteDrivers;
  final double? passengerRating;
  final int? totalTripsAsPassenger;
  
  // Settings & Preferences
  final bool notificationsEnabled;
  final bool locationSharingEnabled;
  final String preferredLanguage;
  final String preferredCurrency;

  // Feature: Gender — used for women-only ride matching
  final String? gender; // 'male', 'female', 'other'

  // Feature: Business profile — for corporate accounts and expense receipts
  final bool isBusinessAccount;
  final String? businessName;
  final String? businessTaxId;
  final String? businessAddress;

  // Feature: Driver session — tracks when driver started online session
  final DateTime? driverSessionStartedAt;

  // Feature: Selfie verification — tracks selfie identity check status
  final String? selfieVerificationStatus; // 'pending', 'verified', 'rejected', null

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    
    // Profile
    this.profileImageUrl,
    this.age,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    
    // Driver Fields
    this.licensePlate,
    this.driverCategory,
    this.carMake,
    this.carModel,
    this.carColor,
    this.carYear,
    this.averageRating,
    this.totalRides,
    this.isDriverActive,
    this.driverApplicationStatus,
    this.driverApprovedAt,
    
    // Passenger Fields
    this.favoriteDrivers = const [],
    this.passengerRating,
    this.totalTripsAsPassenger,
    
    // Settings
    this.notificationsEnabled = true,
    this.locationSharingEnabled = true,
    this.preferredLanguage = 'ro',
    this.preferredCurrency = 'RON',
    this.gender,
    this.isBusinessAccount = false,
    this.businessName,
    this.businessTaxId,
    this.businessAddress,
    this.driverSessionStartedAt,
    this.selfieVerificationStatus,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      
      // Profile
      'profileImageUrl': profileImageUrl,
      'age': age,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      
      // Driver Fields
      'licensePlate': licensePlate,
      'driverCategory': driverCategory,
      'carMake': carMake,
      'carModel': carModel,
      'carColor': carColor,
      'carYear': carYear,
      'averageRating': averageRating,
      'totalRides': totalRides,
      'isDriverActive': isDriverActive,
      'driverApplicationStatus': driverApplicationStatus,
      'driverApprovedAt': driverApprovedAt != null ? Timestamp.fromDate(driverApprovedAt!) : null,
      
      // Passenger Fields
      'favoriteDrivers': favoriteDrivers,
      'passengerRating': passengerRating,
      'totalTripsAsPassenger': totalTripsAsPassenger,
      
      // Settings
      'notificationsEnabled': notificationsEnabled,
      'locationSharingEnabled': locationSharingEnabled,
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'gender': gender,
      'isBusinessAccount': isBusinessAccount,
      'businessName': businessName,
      'businessTaxId': businessTaxId,
      'businessAddress': businessAddress,
      'driverSessionStartedAt': driverSessionStartedAt != null ? Timestamp.fromDate(driverSessionStartedAt!) : null,
      'selfieVerificationStatus': selfieVerificationStatus,
    };
  }

  // Create from Firestore Document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'passenger'),
        orElse: () => UserRole.passenger,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      
      // Profile
      profileImageUrl: data['profileImageUrl'],
      age: data['age'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      
      // Driver Fields
      licensePlate: data['licensePlate'],
      driverCategory: data['driverCategory'],
      carMake: data['carMake'],
      carModel: data['carModel'],
      carColor: data['carColor'],
      carYear: data['carYear'],
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      totalRides: data['totalRides'],
      isDriverActive: data['isDriverActive'],
      driverApplicationStatus: data['driverApplicationStatus'],
      driverApprovedAt: (data['driverApprovedAt'] as Timestamp?)?.toDate(),
      
      // Passenger Fields
      favoriteDrivers: List<String>.from(data['favoriteDrivers'] ?? []),
      passengerRating: (data['passengerRating'] as num?)?.toDouble(),
      totalTripsAsPassenger: data['totalTripsAsPassenger'],
      
      // Settings
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      locationSharingEnabled: data['locationSharingEnabled'] ?? true,
      preferredLanguage: data['preferredLanguage'] ?? 'ro',
      preferredCurrency: data['preferredCurrency'] ?? 'RON',
      gender: data['gender'],
      isBusinessAccount: data['isBusinessAccount'] ?? false,
      businessName: data['businessName'],
      businessTaxId: data['businessTaxId'],
      businessAddress: data['businessAddress'],
      driverSessionStartedAt: (data['driverSessionStartedAt'] as Timestamp?)?.toDate(),
      selfieVerificationStatus: data['selfieVerificationStatus'],
    );
  }

  // Helper Methods
  bool get isDriver => role == UserRole.driver;
  bool get isPassenger => role == UserRole.passenger;
  bool get isDriverApproved => driverApplicationStatus == 'approved';
  bool get isDriverPending => driverApplicationStatus == 'pending_review';
  bool get isDriverRejected => driverApplicationStatus == 'rejected';
  
  String get fullCarInfo {
    if (carMake == null || carModel == null) return 'N/A';
    return '$carMake $carModel ${carYear != null ? '($carYear)' : ''}';
  }
  
  String get driverCategoryDisplay {
    switch (driverCategory) {
      case 'standard':
        return 'Standard';
      case 'energy':
        return 'Eco/Electric';
      case 'best':
        return 'Premium';
      default:
        return 'Standard';
    }
  }
  
  RideCategory? get driverRideCategory {
    switch (driverCategory) {
      case 'standard':
        return RideCategory.standard;
      case 'energy':
        return RideCategory.energy;
      case 'best':
        return RideCategory.best;
      default:
        return null;
    }
  }

  // Copy with method for immutable updates
  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    UserRole? role,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    String? age,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? licensePlate,
    String? driverCategory,
    String? carMake,
    String? carModel,
    String? carColor,
    String? carYear,
    double? averageRating,
    int? totalRides,
    bool? isDriverActive,
    String? driverApplicationStatus,
    DateTime? driverApprovedAt,
    List<String>? favoriteDrivers,
    double? passengerRating,
    int? totalTripsAsPassenger,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
    String? preferredLanguage,
    String? preferredCurrency,
    String? gender,
    bool? isBusinessAccount,
    String? businessName,
    String? businessTaxId,
    String? businessAddress,
    DateTime? driverSessionStartedAt,
    String? selfieVerificationStatus,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      age: age ?? this.age,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      licensePlate: licensePlate ?? this.licensePlate,
      driverCategory: driverCategory ?? this.driverCategory,
      carMake: carMake ?? this.carMake,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      carYear: carYear ?? this.carYear,
      averageRating: averageRating ?? this.averageRating,
      totalRides: totalRides ?? this.totalRides,
      isDriverActive: isDriverActive ?? this.isDriverActive,
      driverApplicationStatus: driverApplicationStatus ?? this.driverApplicationStatus,
      driverApprovedAt: driverApprovedAt ?? this.driverApprovedAt,
      favoriteDrivers: favoriteDrivers ?? this.favoriteDrivers,
      passengerRating: passengerRating ?? this.passengerRating,
      totalTripsAsPassenger: totalTripsAsPassenger ?? this.totalTripsAsPassenger,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      gender: gender ?? this.gender,
      isBusinessAccount: isBusinessAccount ?? this.isBusinessAccount,
      businessName: businessName ?? this.businessName,
      businessTaxId: businessTaxId ?? this.businessTaxId,
      businessAddress: businessAddress ?? this.businessAddress,
      driverSessionStartedAt: driverSessionStartedAt ?? this.driverSessionStartedAt,
      selfieVerificationStatus: selfieVerificationStatus ?? this.selfieVerificationStatus,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}