// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  customerId: json['customerId'] as String,
  merchantId: json['merchantId'] as String,
  totalAmount: (json['totalAmount'] as num).toDouble(),
  status: json['status'] as String,
  shippingAddress: json['shippingAddress'] as String?,
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  items:
      (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'customerId': instance.customerId,
  'merchantId': instance.merchantId,
  'totalAmount': instance.totalAmount,
  'status': instance.status,
  'shippingAddress': instance.shippingAddress,
  'notes': instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'items': instance.items,
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  priceAtPurchase: (json['priceAtPurchase'] as num).toDouble(),
  product:
      json['product'] == null
          ? null
          : Product.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'priceAtPurchase': instance.priceAtPurchase,
  'product': instance.product,
};

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  merchantName: json['merchantName'] as String?,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'price': instance.price,
  'images': instance.images,
  'merchantName': instance.merchantName,
};
