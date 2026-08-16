import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';

part 'cart_item_model.g.dart';

@JsonSerializable()
class CartItem {
  final String id;
  final String customerId;
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Product product;

  const CartItem({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  CartItem copyWith({
    String? id,
    String? customerId,
    String? productId,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }
}
