import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item_model.dart';

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String shippingAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String paymentMethod;
  final String? prescriptionUrl;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.shippingAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.paymentMethod,
    this.prescriptionUrl,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final List<OrderItem> orderItems = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      items: orderItems,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'] ?? 'cash',
      prescriptionUrl: data['prescriptionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'shippingAddress': shippingAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'paymentMethod': paymentMethod,
      'prescriptionUrl': prescriptionUrl,
    };
  }

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }
}
