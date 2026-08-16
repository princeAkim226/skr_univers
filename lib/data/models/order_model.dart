import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable()
class Order {
  final String id;
  final String customerId;
  final String merchantId;
  final double totalAmount;
  final String status;
  final String? shippingAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.customerId,
    required this.merchantId,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  Order copyWith({
    String? id,
    String? customerId,
    String? merchantId,
    double? totalAmount,
    String? status,
    String? shippingAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      merchantId: merchantId ?? this.merchantId,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

@JsonSerializable()
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double priceAtPurchase;
  final Product? product;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

@JsonSerializable()
class Product {
  final String id;
  final String title;
  final String? description;
  final double price;
  final List<String>? images;
  final String? merchantName;

  const Product({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.images,
    this.merchantName,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
