class ScheduleModel {
  final String id;
  final String carRegistrationNumber;
  final String yearOfRegistration;
  final String ownerName;
  final int ownershipSerialNumber;
  final String make;
  final String model;
  final String variant;
  final String emailAddress;
  final String appointmentSource;
  final String vehicleStatus;
  final String zipCode;
  final String customerContactNumber;
  final String city;
  final String yearOfManufacture;
  final String allocatedTo;
  final String inspectionStatus;
  final String approvalStatus;
  final String priority;
  final String ncdUcdName;
  final String repName;
  final String repContact;
  final String bankSource;
  final String referenceName;
  final String remarks;
  final String createdBy;
  final int odometerReadingInKms;
  final String additionalNotes;
  final List<String> carImages;
  final DateTime? inspectionDateTime;
  final String inspectionAddress;
  final String inspectionEngineerNumber;
  final String addedBy;
  final DateTime? timeStamp;
  final String appointmentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScheduleModel({
    required this.id,
    required this.carRegistrationNumber,
    required this.yearOfRegistration,
    required this.ownerName,
    required this.ownershipSerialNumber,
    required this.make,
    required this.model,
    required this.variant,
    required this.emailAddress,
    required this.appointmentSource,
    required this.vehicleStatus,
    required this.zipCode,
    required this.customerContactNumber,
    required this.city,
    required this.yearOfManufacture,
    required this.allocatedTo,
    required this.inspectionStatus,
    required this.approvalStatus,
    required this.priority,
    required this.ncdUcdName,
    required this.repName,
    required this.repContact,
    required this.bankSource,
    required this.referenceName,
    required this.remarks,
    required this.createdBy,
    required this.odometerReadingInKms,
    required this.additionalNotes,
    required this.carImages,
    required this.inspectionDateTime,
    required this.inspectionAddress,
    required this.inspectionEngineerNumber,
    required this.addedBy,
    required this.timeStamp,
    required this.appointmentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['_id'] ?? '',
      carRegistrationNumber: json['carRegistrationNumber'] ?? '',
      yearOfRegistration: json['yearOfRegistration'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownershipSerialNumber: json['ownershipSerialNumber'] ?? 0,
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      variant: json['variant'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      appointmentSource: json['appointmentSource'] ?? '',
      vehicleStatus: json['vehicleStatus'] ?? '',
      zipCode: json['zipCode'] ?? '',
      customerContactNumber: json['customerContactNumber'] ?? '',
      city: json['city'] ?? '',
      yearOfManufacture: json['yearOfManufacture'] ?? '',
      allocatedTo: json['allocatedTo'] ?? '',
      inspectionStatus: json['inspectionStatus'] ?? 'Pending',
      approvalStatus: json['approvalStatus'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
      ncdUcdName: json['ncdUcdName'] ?? '',
      repName: json['repName'] ?? '',
      repContact: json['repContact'] ?? '',
      bankSource: json['bankSource'] ?? '',
      referenceName: json['referenceName'] ?? '',
      remarks: json['remarks'] ?? '',
      createdBy: json['createdBy'] ?? '',
      odometerReadingInKms: json['odometerReadingInKms'] ?? 0,
      additionalNotes: json['additionalNotes'] ?? '',
      carImages: List<String>.from(json['carImages'] ?? []),
      inspectionDateTime:
          json['inspectionDateTime'] != null
              ? DateTime.tryParse(json['inspectionDateTime'])?.toLocal()
              : null,
      inspectionAddress: json['inspectionAddress'] ?? '',
      inspectionEngineerNumber: json['inspectionEngineerNumber'] ?? '',
      addedBy: json['addedBy'] ?? '',
      timeStamp:
          json['timeStamp'] != null
              ? DateTime.tryParse(json['timeStamp'])?.toLocal()
              : null,
      appointmentId: json['appointmentId'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])?.toLocal()
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])?.toLocal()
              : null,
    );
  }

  /// Get formatted date string
  String get formattedInspectionDate {
    if (inspectionDateTime == null) return 'Not scheduled';
    final d = inspectionDateTime!;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Get full car name
  String get fullCarName => '$make $model';

  ScheduleModel copyWith({
    String? make,
    String? model,
    String? variant,
    String? inspectionStatus,
    // Add more fields if needed
  }) {
    return ScheduleModel(
      id: id,
      carRegistrationNumber: carRegistrationNumber,
      yearOfRegistration: yearOfRegistration,
      ownerName: ownerName,
      ownershipSerialNumber: ownershipSerialNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      emailAddress: emailAddress,
      appointmentSource: appointmentSource,
      vehicleStatus: vehicleStatus,
      zipCode: zipCode,
      customerContactNumber: customerContactNumber,
      city: city,
      yearOfManufacture: yearOfManufacture,
      allocatedTo: allocatedTo,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      approvalStatus: approvalStatus,
      priority: priority,
      ncdUcdName: ncdUcdName,
      repName: repName,
      repContact: repContact,
      bankSource: bankSource,
      referenceName: referenceName,
      remarks: remarks,
      createdBy: createdBy,
      odometerReadingInKms: odometerReadingInKms,
      additionalNotes: additionalNotes,
      carImages: carImages,
      inspectionDateTime: inspectionDateTime,
      inspectionAddress: inspectionAddress,
      inspectionEngineerNumber: inspectionEngineerNumber,
      addedBy: addedBy,
      timeStamp: timeStamp,
      appointmentId: appointmentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
