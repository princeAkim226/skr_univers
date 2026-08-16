// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  userType: json['userType'] as String,
  profileImage: json['profileImage'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool,
  businessName: json['businessName'] as String?,
  businessDescription: json['businessDescription'] as String?,
  businessAddress: json['businessAddress'] as String?,
  businessPhone: json['businessPhone'] as String?,
  businessEmail: json['businessEmail'] as String?,
  isVerified: json['isVerified'] as bool?,
  interests:
      (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'phoneNumber': instance.phoneNumber,
  'userType': instance.userType,
  'profileImage': instance.profileImage,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'businessName': instance.businessName,
  'businessDescription': instance.businessDescription,
  'businessAddress': instance.businessAddress,
  'businessPhone': instance.businessPhone,
  'businessEmail': instance.businessEmail,
  'isVerified': instance.isVerified,
  'interests': instance.interests,
};
