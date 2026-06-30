// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medicore/models/order_model.dart';
import 'package:medicore/models/order_item_model.dart';
import 'package:medicore/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  Order? _latestPlacedOrder;
  StreamSubscription<List<Order>>? _ordersSubscription;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Subscribes to a real-time stream of the user's orders.
  /// Call this once when the user logs in; cancel via [cancelSubscription] on logout.
  void subscribeToUserOrders(String userId) {
    _ordersSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _ordersSubscription =
        _orderService.getUserOrders(userId).listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
        print('Order stream error: $e');
        notifyListeners();
      },
    );
  }

  void cancelSubscription() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _orders = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  // One-shot fetch fallback (used by order screen refresh)
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final orders = await _orderService.getUserOrders(userId).first;
      _orders = orders;
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
      print('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Places an order. Separated from loadUserOrders so a stream/index error
  /// doesn't prevent a successful order from being acknowledged.
  Future<bool> placeOrder({
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
    _errorMessage = null;

    try {
      final order = await _orderService.placeOrder(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        shippingAddress: shippingAddress,
        items: items,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        prescriptionUrl: prescriptionUrl,
      );
      _latestPlacedOrder = order;
      // The real-time subscription will automatically push the new order.
      // If there is no subscription yet, do a one-shot refresh.
      if (_ordersSubscription == null) {
        await loadUserOrders(userId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to place order: $e';
      print('Error placing order: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, String userId) async {
    _errorMessage = null;
    try {
      await _orderService.cancelOrder(orderId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error cancelling order: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(
      String orderId, String newStatus, String userId) async {
    _errorMessage = null;
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update order status: $e';
      print('Error updating order status: $e');
      notifyListeners();
      return false;
    }
  }

  List<Order> getOrdersByStatus(String status) =>
      _orders.where((o) => o.status == status).toList();

  List<Order> get pendingOrders => getOrdersByStatus('pending');
  List<Order> get confirmedOrders => getOrdersByStatus('confirmed');
  List<Order> get shippedOrders => getOrdersByStatus('shipped');
  List<Order> get deliveredOrders => getOrdersByStatus('delivered');
  List<Order> get cancelledOrders => getOrdersByStatus('cancelled');

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  /// The most recently placed order (set synchronously in placeOrder).
  Order? get latestOrder => _latestPlacedOrder ?? (_orders.isNotEmpty ? _orders.first : null);

  bool get hasOrders => _orders.isNotEmpty;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Map<String, dynamic> get orderStatistics => {
        'total': _orders.length,
        'pending': pendingOrders.length,
        'confirmed': confirmedOrders.length,
        'shipped': shippedOrders.length,
        'delivered': deliveredOrders.length,
        'cancelled': cancelledOrders.length,
        'totalAmount':
            _orders.fold(0.0, (sum, o) => sum + o.totalAmount),
      };

  List<Order> searchOrders(String query) {
    if (query.isEmpty) return _orders;
    final q = query.toLowerCase();
    return _orders.where((o) {
      return o.id.toLowerCase().contains(q) ||
          o.items.any((i) => i.medicineName.toLowerCase().contains(q)) ||
          o.status.toLowerCase().contains(q);
    }).toList();
  }
}
