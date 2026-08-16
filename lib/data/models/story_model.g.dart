// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
  id: json['id'] as String,
  merchantId: json['merchantId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  videoUrl: json['videoUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  isActive: json['isActive'] as bool,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  location: json['location'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
  'id': instance.id,
  'merchantId': instance.merchantId,
  'title': instance.title,
  'description': instance.description,
  'images': instance.images,
  'videoUrl': instance.videoUrl,
  'createdAt': instance.createdAt.toIso8601String(),
  'expiresAt': instance.expiresAt.toIso8601String(),
  'isActive': instance.isActive,
  'viewCount': instance.viewCount,
  'tags': instance.tags,
  'location': instance.location,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
