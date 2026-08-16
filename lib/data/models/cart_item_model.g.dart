// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  id: json['id'] as String,
  customerId: json['customerId'] as String,
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  product: Product.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'id': instance.id,
  'customerId': instance.customerId,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'product': instance.product,
};
