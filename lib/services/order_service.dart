// services/order_service.dart
// ignore_for_file: avoid_print, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/order_model.dart' as medicore;
import 'package:medicore/services/push_notification_service.dart';
import 'package:medicore/models/order_item_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all orders for admin (real-time)
  Stream<List<medicore.Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => medicore.Order.fromFirestore(doc))
            .toList());
  }

  // Get orders by status for admin
  Stream<List<medicore.Order>> getOrdersByStatus(String status) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => medicore.Order.fromFirestore(doc))
            .toList());
  }

  // Get today's orders
  Stream<List<medicore.Order>> getTodaysOrders() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('orders')
        .where('orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => medicore.Order.fromFirestore(doc))
            .toList());
  }

  // Search orders
  Stream<List<medicore.Order>> searchOrders(String query) {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final allOrders = snapshot.docs
          .map((doc) => medicore.Order.fromFirestore(doc))
          .toList();

      return allOrders.where((order) {
        return order.id.toLowerCase().contains(query.toLowerCase()) ||
            order.userName.toLowerCase().contains(query.toLowerCase()) ||
            order.userEmail.toLowerCase().contains(query.toLowerCase()) ||
            order.status.toLowerCase().contains(query.toLowerCase()) ||
            order.items.any((item) =>
                item.medicineName.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Read current order for context
      final doc = await _firestore.collection('orders').doc(orderId).get();
      final order = doc.exists ? medicore.Order.fromFirestore(doc) : null;

      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Set delivery date if order is delivered
      if (newStatus == 'delivered') {
        updateData['deliveryDate'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Local notification on status change (best effort)
      try {
        if (order != null) {
          String title = 'অর্ডার আপডেট';
          String body = 'অর্ডার #${order.id.substring(0, 8)}: $newStatus';
          switch (newStatus) {
            case 'confirmed':
              title = 'অর্ডার নিশ্চিত';
              body = 'অর্ডার #${order.id.substring(0, 8)} নিশ্চিত হয়েছে।';
              break;
            case 'shipped':
              title = 'অর্ডার শিপড';
              body = 'অর্ডার #${order.id.substring(0, 8)} পাঠানো হয়েছে।';
              break;
            case 'delivered':
              title = 'অর্ডার ডেলিভার্ড';
              body = 'অর্ডার #${order.id.substring(0, 8)} ডেলিভারি সম্পন্ন।';
              break;
            case 'cancelled':
              title = 'অর্ডার বাতিল';
              body = 'অর্ডার #${order.id.substring(0, 8)} বাতিল হয়েছে।';
              break;
            default:
              title = 'অর্ডার আপডেট';
              body = 'অর্ডার #${order.id.substring(0, 8)}: $newStatus';
          }
          await PushNotificationService.instance.showLocalNotification(
            title: title,
            body: body,
            payload: {
              'type': 'order',
              'orderId': order.id,
            },
          );
        }
      } catch (_) {}
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get order statistics for admin
  Future<Map<String, dynamic>> getAdminOrderStatistics() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      final orders = ordersSnapshot.docs
          .map((doc) => medicore.Order.fromFirestore(doc))
          .toList();

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todaysOrders =
          orders.where((order) => order.orderDate.isAfter(startOfDay)).toList();

      return {
        'totalOrders': orders.length,
        'pendingOrders': orders.where((o) => o.status == 'pending').length,
        'confirmedOrders': orders.where((o) => o.status == 'confirmed').length,
        'shippedOrders': orders.where((o) => o.status == 'shipped').length,
        'deliveredOrders': orders.where((o) => o.status == 'delivered').length,
        'cancelledOrders': orders.where((o) => o.status == 'cancelled').length,
        'todaysOrders': todaysOrders.length,
        'totalRevenue': orders
            .where((o) => o.status == 'delivered')
            .fold(0.0, (sum, order) => sum + order.totalAmount),
        'pendingRevenue': orders
            .where((o) => o.status == 'pending')
            .fold(0.0, (sum, order) => sum + order.totalAmount),
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'confirmedOrders': 0,
        'shippedOrders': 0,
        'deliveredOrders': 0,
        'cancelledOrders': 0,
        'todaysOrders': 0,
        'totalRevenue': 0.0,
        'pendingRevenue': 0.0,
      };
    }
  }

  // Delete order (admin only)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
      throw Exception('Failed to delete order: $e');
    }
  }

  // Get recent orders (last 7 days)
  Stream<List<medicore.Order>> getRecentOrders() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection('orders')
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => medicore.Order.fromFirestore(doc))
            .toList());
  }

  // Existing methods...
  Stream<List<medicore.Order>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => medicore.Order.fromFirestore(doc))
            .toList());
  }

  Future<medicore.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      return doc.exists ? medicore.Order.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  Future<medicore.Order> placeOrder({
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String shippingAddress,
    required List<OrderItem> items,
    required double totalAmount,
    required String paymentMethod,
    String? prescriptionUrl,
  }) async {
    try {
      final docRef = _firestore.collection('orders').doc();

      final order = medicore.Order(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        shippingAddress: shippingAddress,
        items: items,
        totalAmount: totalAmount,
        status: 'pending',
        orderDate: DateTime.now(),
        paymentMethod: paymentMethod,
        prescriptionUrl: prescriptionUrl,
      );

      await docRef.set(order.toMap());

      // Notify user that the order has been placed
      try {
        await PushNotificationService.instance.showLocalNotification(
          title: 'Order placed',
          body:
              'Your order #${docRef.id.substring(0, 8)} for ৳${totalAmount.toStringAsFixed(2)} has been placed.',
          payload: {
            'type': 'order',
            'orderId': docRef.id,
          },
        );
      } catch (_) {
        // Do not block on notification failures
      }
      return order;
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) {
        throw Exception('Order not found');
      }
      final order = medicore.Order.fromFirestore(doc);
      final now = DateTime.now();
      final diff = now.difference(order.orderDate);
      if (diff > const Duration(minutes: 30)) {
        throw Exception(
            'Order can only be cancelled within 30 minutes of placement');
      }
      if (['shipped', 'delivered', 'cancelled'].contains(order.status)) {
        throw Exception('Order cannot be cancelled in current status');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Local notification for cancellation
      try {
        await PushNotificationService.instance.showLocalNotification(
          title: 'অর্ডার বাতিল',
          body: 'অর্ডার #${order.id.substring(0, 8)} বাতিল হয়েছে।',
          payload: {
            'type': 'order',
            'orderId': order.id,
          },
        );
      } catch (_) {}
    } catch (e) {
      print('Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }
}
