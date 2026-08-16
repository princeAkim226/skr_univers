import 'package:json_annotation/json_annotation.dart';

part 'story_model.g.dart';

@JsonSerializable()
class Story {
  final String id;
  final String merchantId;
  final String title;
  final String? description;
  final List<String> images;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final int viewCount;
  final List<String> tags;
  final String? location;
  final double? latitude;
  final double? longitude;

  Story({
    required this.id,
    required this.merchantId,
    required this.title,
    this.description,
    required this.images,
    this.videoUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    this.viewCount = 0,
    this.tags = const [],
    this.location,
    this.latitude,
    this.longitude,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  Story copyWith({
    String? id,
    String? merchantId,
    String? title,
    String? description,
    List<String>? images,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    int? viewCount,
    List<String>? tags,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return Story(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
