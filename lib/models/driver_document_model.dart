enum DriverDocumentStatus {
  pending,
  approved,
  rejected;

  static DriverDocumentStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return DriverDocumentStatus.approved;
      case 'rejected':
        return DriverDocumentStatus.rejected;
      default:
        return DriverDocumentStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case DriverDocumentStatus.pending:
        return 'pending';
      case DriverDocumentStatus.approved:
        return 'approved';
      case DriverDocumentStatus.rejected:
        return 'rejected';
    }
  }
}

enum DriverDocumentType {
  profilePhoto,
  idCard,
  drivingLicenseFront,
  drivingLicenseBack,
  carExterior,
  carInsurance,
  criminalRecord,
  transportAttestation,
}

extension DriverDocumentTypeExtension on DriverDocumentType {
  String get displayName {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'Poză de Profil';
      case DriverDocumentType.idCard:
        return 'Carte de Identitate';
      case DriverDocumentType.drivingLicenseFront:
        return 'Permis de Conducere (față)';
      case DriverDocumentType.drivingLicenseBack:
        return 'Permis de Conducere (verso)';
      case DriverDocumentType.carExterior:
        return 'Poză Mașină (exterior)';
      case DriverDocumentType.carInsurance:
        return 'Asigurare RCA';
      case DriverDocumentType.criminalRecord:
        return 'Cazier Judiciar';
      case DriverDocumentType.transportAttestation:
        return 'Atestat Transport Persoane';
    }
  }
  
  String get storageFolder {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'profile_photos';
      case DriverDocumentType.idCard:
        return 'id_cards';
      case DriverDocumentType.drivingLicenseFront:
        return 'driving_licenses_front';
      case DriverDocumentType.drivingLicenseBack:
        return 'driving_licenses_back';
      case DriverDocumentType.carExterior:
        return 'car_photos';
      case DriverDocumentType.carInsurance:
        return 'car_insurance';
      case DriverDocumentType.criminalRecord:
        return 'criminal_records';
      case DriverDocumentType.transportAttestation:
        return 'transport_attestations';
    }
  }
  
  String get firestoreField {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'profilePhotoUrl';
      case DriverDocumentType.idCard:
        return 'idCardUrl';
      case DriverDocumentType.drivingLicenseFront:
        return 'drivingLicenseFrontUrl';
      case DriverDocumentType.drivingLicenseBack:
        return 'drivingLicenseBackUrl';
      case DriverDocumentType.carExterior:
        return 'carExteriorUrl';
      case DriverDocumentType.carInsurance:
        return 'carInsuranceUrl';
      case DriverDocumentType.criminalRecord:
        return 'criminalRecordUrl';
      case DriverDocumentType.transportAttestation:
        return 'transportAttestationUrl';
    }
  }
  
  String get description {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'Fotografie recentă pentru profilul dvs.';
      case DriverDocumentType.idCard:
        return 'Carte de identitate română valabilă';
      case DriverDocumentType.drivingLicenseFront:
        return 'Partea din față a permisului de conducere';
      case DriverDocumentType.drivingLicenseBack:
        return 'Partea din spate a permisului de conducere';
      case DriverDocumentType.carExterior:
        return 'Fotografie cu mașina din exterior';
      case DriverDocumentType.carInsurance:
        return 'Certificat de asigurare RCA valabil';
      case DriverDocumentType.criminalRecord:
        return 'Cazier judiciar emis în ultimele 3 luni';
      case DriverDocumentType.transportAttestation:
        return 'Atestat pentru transportul de persoane';
    }
  }
  
  bool get isRequired {
    switch (this) {
      case DriverDocumentType.profilePhoto:
      case DriverDocumentType.idCard:
      case DriverDocumentType.drivingLicenseFront:
      case DriverDocumentType.drivingLicenseBack:
      case DriverDocumentType.carExterior:
      case DriverDocumentType.carInsurance:
        return true;
      case DriverDocumentType.criminalRecord:
      case DriverDocumentType.transportAttestation:
        return false; // Opționale sau depind de localitate
    }
  }
}

class DriverDocument {
  final DriverDocumentType type;
  final String? url;
  final DateTime? uploadedAt;
  final String? fileName;
  final bool isUploaded;
  final DriverDocumentStatus status;
  final String? rejectionReason;
  final DateTime? expiryDate;

  DriverDocument({
    required this.type,
    this.url,
    this.uploadedAt,
    this.fileName,
    this.isUploaded = false,
    this.status = DriverDocumentStatus.pending,
    this.rejectionReason,
    this.expiryDate,
  });

  factory DriverDocument.fromFirestore(DriverDocumentType type, Map<String, dynamic>? data) {
    if (data == null) {
      return DriverDocument(type: type);
    }

    return DriverDocument(
      type: type,
      url: data[type.firestoreField],
      uploadedAt: data['${type.firestoreField}_uploadedAt']?.toDate(),
      fileName: data['${type.firestoreField}_fileName'],
      isUploaded: data[type.firestoreField] != null,
      status: DriverDocumentStatus.fromString(data['${type.name}_status'] as String?),
      rejectionReason: data['${type.name}_rejectionReason'] as String?,
      expiryDate: (data['${type.name}_expiryDate'] as dynamic)?.toDate(),
    );
  }

  DriverDocument copyWith({
    String? url,
    DateTime? uploadedAt,
    String? fileName,
    bool? isUploaded,
    DriverDocumentStatus? status,
    String? rejectionReason,
    DateTime? expiryDate,
  }) {
    return DriverDocument(
      type: type,
      url: url ?? this.url,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileName: fileName ?? this.fileName,
      isUploaded: isUploaded ?? this.isUploaded,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return !isExpired && expiryDate!.isBefore(thirtyDaysFromNow);
  }
}

class DriverApplicationData {
  final String? fullName;
  final String? age;
  final String? carBrand;
  final String? carModel;
  final String? carColor;
  final String? carYear;
  final String? licensePlate;
  final String? bankAccount;
  final Map<DriverDocumentType, DriverDocument> documents;
  final DateTime? submittedAt;
  final String status; // 'draft'|'submitted'|'under_review'|'approved'|'rejected'|'activated'
  final String? accessCode;
  final DateTime? accessCodeGeneratedAt;

  DriverApplicationData({
    this.fullName,
    this.age,
    this.carBrand,
    this.carModel,
    this.carColor,
    this.carYear,
    this.licensePlate,
    this.bankAccount,
    this.documents = const {},
    this.submittedAt,
    this.status = 'draft',
    this.accessCode,
    this.accessCodeGeneratedAt,
  });

  factory DriverApplicationData.fromFirestore(Map<String, dynamic> data) {
    final documents = <DriverDocumentType, DriverDocument>{};
    
    for (final docType in DriverDocumentType.values) {
      documents[docType] = DriverDocument.fromFirestore(docType, data);
    }
    
    return DriverApplicationData(
      fullName: data['fullName'],
      age: data['age'],
      carBrand: data['carBrand'],
      carModel: data['carModel'],
      carColor: data['carColor'],
      carYear: data['carYear'],
      licensePlate: data['licensePlate'],
      bankAccount: data['bankAccount'],
      documents: documents,
      submittedAt: data['submittedAt']?.toDate(),
      status: data['status'] ?? 'draft',
      accessCode: data['accessCode'] as String?,
      accessCodeGeneratedAt: (data['accessCodeGeneratedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'fullName': fullName,
      'age': age,
      'carBrand': carBrand,
      'carModel': carModel,
      'carColor': carColor,
      'carYear': carYear,
      'licensePlate': licensePlate,
      'bankAccount': bankAccount,
      'status': status,
      'submittedAt': submittedAt,
    };

    // Adaugă documentele
    for (final entry in documents.entries) {
      final docType = entry.key;
      final document = entry.value;
      
      if (document.isUploaded) {
        data[docType.firestoreField] = document.url;
        data['${docType.firestoreField}_uploadedAt'] = document.uploadedAt;
        data['${docType.firestoreField}_fileName'] = document.fileName;
        data['${docType.name}_status'] = document.status.value;
        if (document.rejectionReason != null) {
          data['${docType.name}_rejectionReason'] = document.rejectionReason;
        }
        if (document.expiryDate != null) {
          data['${docType.name}_expiryDate'] = document.expiryDate;
        }
      }
    }

    return data;
  }

  bool get isComplete {
    // Verifică dacă toate documentele obligatorii sunt încărcate
    final requiredDocs = DriverDocumentType.values.where((doc) => doc.isRequired);
    return requiredDocs.every((docType) => documents[docType]?.isUploaded == true) &&
           fullName != null && fullName!.isNotEmpty &&
           age != null && age!.isNotEmpty &&
           carBrand != null && carBrand!.isNotEmpty &&
           carModel != null && carModel!.isNotEmpty &&
           licensePlate != null && licensePlate!.isNotEmpty;
  }

  double get completionPercentage {
    final totalRequired = DriverDocumentType.values.where((doc) => doc.isRequired).length + 5; // +5 pentru câmpurile obligatorii
    int completed = 0;

    // Verifică documentele obligatorii
    final requiredDocs = DriverDocumentType.values.where((doc) => doc.isRequired);
    for (final docType in requiredDocs) {
      if (documents[docType]?.isUploaded == true) completed++;
    }

    // Verifică câmpurile obligatorii
    if (fullName != null && fullName!.isNotEmpty) completed++;
    if (age != null && age!.isNotEmpty) completed++;
    if (carBrand != null && carBrand!.isNotEmpty) completed++;
    if (carModel != null && carModel!.isNotEmpty) completed++;
    if (licensePlate != null && licensePlate!.isNotEmpty) completed++;

    return completed / totalRequired;
  }
}