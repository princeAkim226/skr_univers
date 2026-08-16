import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class Product {
  final String id;
  final String merchantId;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final int stockQuantity;
  final List<String> images;
  final String category;
  final List<String> tags;
  // Champs spécifiques Habitation
  final String? propertyGoal; // vente/location
  final String? propertyType; // maison, magasin, etc.
  final String? propertyCity;
  final String? propertyZone;
  final String? propertyQuarter;
  final int? propertyRooms;
  final double? propertySurface;
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Coordonnées de localisation
  final double? latitude;
  final double? longitude;
  final String? address;
  
  // Informations sur le vendeur
  final String merchantName;
  final String? merchantImage;
  final bool merchantVerified;

  Product({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.stockQuantity,
    required this.images,
    required this.category,
    required this.tags,
    this.propertyGoal,
    this.propertyType,
    this.propertyCity,
    this.propertyZone,
    this.propertyQuarter,
    this.propertyRooms,
    this.propertySurface,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.address,
    required this.merchantName,
    this.merchantImage,
    required this.merchantVerified,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  String get mainImage => images.isNotEmpty ? images.first : '';
  
  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }
  
  bool get isInStock => stockQuantity > 0;
  
  String get formattedPrice => '${price.toStringAsFixed(2)} €';
  String get formattedOriginalPrice => originalPrice != null ? '${originalPrice!.toStringAsFixed(2)} €' : '';

  Product copyWith({
    String? id,
    String? merchantId,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    int? stockQuantity,
    List<String>? images,
    String? category,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? address,
    String? merchantName,
    String? merchantImage,
    bool? merchantVerified,
  }) {
    return Product(
      id: id ?? this.id,
      propertyGoal: propertyGoal ?? this.propertyGoal,
      propertyType: propertyType ?? this.propertyType,
      propertyCity: propertyCity ?? this.propertyCity,
      propertyZone: propertyZone ?? this.propertyZone,
      propertyQuarter: propertyQuarter ?? this.propertyQuarter,
      propertyRooms: propertyRooms ?? this.propertyRooms,
      propertySurface: propertySurface ?? this.propertySurface,
      merchantId: merchantId ?? this.merchantId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      merchantName: merchantName ?? this.merchantName,
      merchantImage: merchantImage ?? this.merchantImage,
      merchantVerified: merchantVerified ?? this.merchantVerified,
    );
  }
} 