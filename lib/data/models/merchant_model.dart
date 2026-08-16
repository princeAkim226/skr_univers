import 'package:json_annotation/json_annotation.dart';

part 'merchant_model.g.dart';

@JsonSerializable()
class Merchant {
  final String id;
  final String userId;
  final String businessName;
  final String? businessEmail;
  final String? businessPhone;
  final String? businessAddress;
  final String? businessCity;
  final String businessCountry;
  final String? businessDescription;
  final String? businessImage;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Pièces d'identité
  final String? idCardFront;
  final String? idCardBack;
  final String? idCardType; // CNI, Passeport, etc.
  final DateTime? idCardUploadDate;
  final String? idCardStatus; // pending, approved, rejected
  
  // Coordonnées de localisation
  final double? latitude;
  final double? longitude;
  final String? fullAddress;

  Merchant({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessEmail,
    this.businessPhone,
    this.businessAddress,
    this.businessCity,
    this.businessCountry = 'Burkina Faso',
    this.businessDescription,
    this.businessImage,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.idCardFront,
    this.idCardBack,
    this.idCardType,
    this.idCardUploadDate,
    this.idCardStatus = 'pending',
    this.latitude,
    this.longitude,
    this.fullAddress,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) => _$MerchantFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantToJson(this);

  bool get hasIdCard => idCardFront != null && idCardBack != null;
  bool get isIdCardApproved => idCardStatus == 'approved';
  bool get isIdCardPending => idCardStatus == 'pending';
  bool get isIdCardRejected => idCardStatus == 'rejected';

  String get displayAddress {
    if (fullAddress != null) return fullAddress!;
    if (businessAddress != null && businessCity != null) {
      return '$businessAddress, $businessCity';
    }
    return businessCity ?? businessCountry;
  }

  Merchant copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessCity,
    String? businessCountry,
    String? businessDescription,
    String? businessImage,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? idCardFront,
    String? idCardBack,
    String? idCardType,
    DateTime? idCardUploadDate,
    String? idCardStatus,
    double? latitude,
    double? longitude,
    String? fullAddress,
  }) {
    return Merchant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      businessCity: businessCity ?? this.businessCity,
      businessCountry: businessCountry ?? this.businessCountry,
      businessDescription: businessDescription ?? this.businessDescription,
      businessImage: businessImage ?? this.businessImage,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      idCardFront: idCardFront ?? this.idCardFront,
      idCardBack: idCardBack ?? this.idCardBack,
      idCardType: idCardType ?? this.idCardType,
      idCardUploadDate: idCardUploadDate ?? this.idCardUploadDate,
      idCardStatus: idCardStatus ?? this.idCardStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fullAddress: fullAddress ?? this.fullAddress,
    );
  }
}
