import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String userType; // 'customer' ou 'merchant'
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // Champs spécifiques aux e-commerçants
  final String? businessName;
  final String? businessDescription;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final bool? isVerified;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.userType,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.businessName,
    this.businessDescription,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName => '$firstName $lastName';
  
  bool get isMerchant => userType == 'merchant';
  bool get isCustomer => userType == 'customer';
  
  String get displayName => isMerchant && businessName != null 
      ? businessName! 
      : fullName;

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? userType,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? businessName,
    String? businessDescription,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      isVerified: isVerified ?? this.isVerified,
    );
  }
} 