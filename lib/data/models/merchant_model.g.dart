// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Merchant _$MerchantFromJson(Map<String, dynamic> json) => Merchant(
  id: json['id'] as String,
  userId: json['userId'] as String,
  businessName: json['businessName'] as String,
  businessEmail: json['businessEmail'] as String?,
  businessPhone: json['businessPhone'] as String?,
  businessAddress: json['businessAddress'] as String?,
  businessCity: json['businessCity'] as String?,
  businessCountry: json['businessCountry'] as String? ?? 'Burkina Faso',
  businessDescription: json['businessDescription'] as String?,
  businessImage: json['businessImage'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  idCardFront: json['idCardFront'] as String?,
  idCardBack: json['idCardBack'] as String?,
  idCardType: json['idCardType'] as String?,
  idCardUploadDate:
      json['idCardUploadDate'] == null
          ? null
          : DateTime.parse(json['idCardUploadDate'] as String),
  idCardStatus: json['idCardStatus'] as String? ?? 'pending',
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  fullAddress: json['fullAddress'] as String?,
);

Map<String, dynamic> _$MerchantToJson(Merchant instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'businessName': instance.businessName,
  'businessEmail': instance.businessEmail,
  'businessPhone': instance.businessPhone,
  'businessAddress': instance.businessAddress,
  'businessCity': instance.businessCity,
  'businessCountry': instance.businessCountry,
  'businessDescription': instance.businessDescription,
  'businessImage': instance.businessImage,
  'isVerified': instance.isVerified,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'idCardFront': instance.idCardFront,
  'idCardBack': instance.idCardBack,
  'idCardType': instance.idCardType,
  'idCardUploadDate': instance.idCardUploadDate?.toIso8601String(),
  'idCardStatus': instance.idCardStatus,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'fullAddress': instance.fullAddress,
};
