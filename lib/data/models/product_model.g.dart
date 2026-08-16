// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  merchantId: json['merchantId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  originalPrice: (json['originalPrice'] as num?)?.toDouble(),
  stockQuantity: (json['stockQuantity'] as num).toInt(),
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  category: json['category'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  isActive: json['isActive'] as bool,
  isFeatured: json['isFeatured'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  address: json['address'] as String?,
  merchantName: json['merchantName'] as String,
  merchantImage: json['merchantImage'] as String?,
  merchantVerified: json['merchantVerified'] as bool,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'merchantId': instance.merchantId,
  'title': instance.title,
  'description': instance.description,
  'price': instance.price,
  'originalPrice': instance.originalPrice,
  'stockQuantity': instance.stockQuantity,
  'images': instance.images,
  'category': instance.category,
  'tags': instance.tags,
  'isActive': instance.isActive,
  'isFeatured': instance.isFeatured,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'address': instance.address,
  'merchantName': instance.merchantName,
  'merchantImage': instance.merchantImage,
  'merchantVerified': instance.merchantVerified,
};
