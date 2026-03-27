import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants/enums.dart';
import '../../utils/formatters/formatter.dart';
import 'address_model.dart';

/// Model class representing user data.
class UserModel {
  final String id;
  String fullName;
  String userName;
  String email;
  String phoneNumber;
  String profilePicture;
  AppRole role;

  DateTime? createdAt;
  DateTime? updatedAt;

  bool isProfileActive;
  bool isEmailVerified;
  VerificationStatus verificationStatus;

  String deviceToken;

  final List<AddressModel>? addresses;

  /// Constructor for UserModel.
  UserModel({
    required this.id,
    required this.email,
    this.fullName = '',
    this.userName = '',
    this.phoneNumber = '',
    this.profilePicture = '',
    this.role = AppRole.user,
    this.createdAt,
    this.updatedAt,
    this.deviceToken = '',
    required this.isEmailVerified,
    required this.isProfileActive,
    this.verificationStatus = VerificationStatus.unknown,
    this.addresses,
  });

  /// Helper methods

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  String get formattedDate => TFormatter.formatDateAndTime(createdAt);

  String get formattedUpdatedAtDate => TFormatter.formatDateAndTime(updatedAt);

  /// Static function to split full name into first and last name.
  static List<String> nameParts(fullName) => fullName.split(" ");

  /// Static function to generate a username from the full name.
  static String generateUsername(fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : "";

    String camelCaseUsername =
        "$firstName$lastName"; // Combine first and last name
    String usernameWithPrefix =
        "otobix_$camelCaseUsername"; // Add "otobix_" prefix
    return usernameWithPrefix;
  }

  /// Static function to create an empty user model.
  static UserModel empty() => UserModel(
    id: '',
    email: '',
    isEmailVerified: false,
    isProfileActive: false,
  ); // Default createdAt to current time

  /// Convert model to JSON structure for storing data in Firebase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'role': role.name.toString(),
      'isEmailVerified': isEmailVerified,
      'isProfileActive': isProfileActive,
      'deviceToken': deviceToken,
      'verificationStatus': verificationStatus.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt = DateTime.now(),
    };
  }

  // Factory method to create UserModel from Firestore document snapshot
  factory UserModel.fromDocSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserModel.fromJson(doc.id, data);
  }

  // Static method to create a list of UserModel from QuerySnapshot (for retrieving multiple users)
  static UserModel fromQuerySnapshot(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(doc.id, data);
  }

  /// Factory method to create a UserModel from a Firebase document snapshot.
  factory UserModel.fromJson(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      fullName: data.containsKey('fullName') ? data['fullName'] ?? '' : '',
      userName: data.containsKey('userName') ? data['userName'] ?? '' : '',
      email: data.containsKey('email') ? data['email'] ?? '' : '',
      phoneNumber:
          data.containsKey('phoneNumber') ? data['phoneNumber'] ?? '' : '',
      profilePicture:
          data.containsKey('profilePicture')
              ? data['profilePicture'] ?? ''
              : '',
      role: mapRoleStringToEnum(
        data['role'] ?? data['userRole'] ?? AppRole.user.name,
      ),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      deviceToken:
          data.containsKey('deviceToken') ? data['deviceToken'] ?? '' : '',
      isEmailVerified:
          data.containsKey('isEmailVerified')
              ? data['isEmailVerified'] ?? false
              : false,
      isProfileActive:
          data.containsKey('isProfileActive')
              ? data['isProfileActive'] ?? false
              : false,
      verificationStatus:
          (data.containsKey('verificationStatus'))
              ? _mapVerificationStringToEnum(data['verificationStatus'] ?? '')
              : (data.containsKey('approvalStatus'))
              ? _mapVerificationStringToEnum(data['approvalStatus'] ?? '')
              : VerificationStatus.pending,
    );
  }

  /// Create a copy of the model with updated fields
  UserModel copyWith({
    String? id,
    String? fullName,
    String? userName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    AppRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProfileActive,
    bool? isEmailVerified,
    VerificationStatus? verificationStatus,
    String? deviceToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProfileActive: isProfileActive ?? this.isProfileActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      deviceToken: deviceToken ?? this.deviceToken,
    );
  }

  /// Utility to map a role string to the AppRole enum
  static AppRole mapRoleStringToEnum(dynamic role) {
    if (role == null) return AppRole.user;
    final r = role.toString().toLowerCase().trim();
    if (r == 'admin' || r == 'administrator') return AppRole.admin;
    return AppRole.user;
  }

  /// Utility to parse date from dynamic data (Firebase Timestamp or ISO String)
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  /// Utility to map a status string to the VerificationStatus enum
  static VerificationStatus _mapVerificationStringToEnum(String verification) {
    switch (verification.trim().toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'submitted':
        return VerificationStatus.submitted;
      case 'underreview':
        return VerificationStatus.underReview;
      default:
        return VerificationStatus.unknown;
    }
  }
}
