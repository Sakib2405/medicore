import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medicore/models/payment_model.dart';
import 'package:medicore/services/sslcommerz_service.dart';

enum PaymentMethod { bkash, nagad, rocket, cash, online }

class PaymentService {
  final _ssl = SslCommerzService();
  final _firestore = FirebaseFirestore.instance;

  // Start SSLCommerz payment; returns gateway result and transaction id, but does not persist.
  Future<PaymentGatewayResult?> startSslPayment({
    required BuildContext context,
    required double amount,
    required PaymentMethod method,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? shippingAddress,
  }) async {
    final tranId = 'MEDI_${DateTime.now().millisecondsSinceEpoch}';
    final result = await _ssl.pay(
      context: context,
      tranId: tranId,
      amount: amount,
      method: switch (method) {
        PaymentMethod.bkash => 'bkash',
        PaymentMethod.nagad => 'nagad',
        PaymentMethod.rocket => 'rocket',
        _ => null,
      },
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      shippingAddress: shippingAddress,
    );
    return result;
  }

  Future<void> saveSuccessfulPayment({
    required String tranId,
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? bankTranId,
  }) async {
    final payment = PaymentModel(
      id: tranId,
      orderId: orderId,
      amount: amount,
      method: method.name,
      status: 'successful',
      transactionDate: DateTime.now(),
      currency: 'BDT',
      gatewayTransactionId: bankTranId,
      gateway: 'SSLCommerz',
    );
    await _firestore.collection('payments').doc(tranId).set(payment.toMap());
  }

  Future<PaymentModel> markCashPayment({
    required String orderId,
    required double amount,
  }) async {
    final id = 'CASH_${DateTime.now().millisecondsSinceEpoch}';
    final payment = PaymentModel(
      id: id,
      orderId: orderId,
      amount: amount,
      method: PaymentMethod.cash.name,
      status: 'pending',
      transactionDate: DateTime.now(),
      currency: 'BDT',
      gateway: null,
    );
    await _firestore.collection('payments').doc(id).set(payment.toMap());
    return payment;
  }

  // Unified SSLCommerz payment used across screens; prompts wallet number for mobile gateways
  Future<PaymentModel> processSslPayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required PaymentMethod method,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? shippingAddress,
  }) async {
    // Prompt wallet number for mobile methods
    String phoneToUse = customerPhone;
    if (method != PaymentMethod.cash) {
      final entered = await _promptWalletNumber(
        context,
        initial: (customerPhone).trim(),
        method: method,
      );
      if (entered == null || entered.trim().isEmpty) {
        return PaymentModel(
          id: 'CANCEL_${DateTime.now().millisecondsSinceEpoch}',
          orderId: orderId,
          amount: amount,
          method: method.name,
          status: 'cancelled',
          transactionDate: DateTime.now(),
          gateway: 'SSLCommerz',
        );
      }
      phoneToUse = entered.trim();
    }

    // Create transaction
    final tranId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
    // Guard against using context across async gaps
    if (!context.mounted) {
      return PaymentModel(
        id: 'CANCEL_$tranId',
        orderId: orderId,
        amount: amount,
        method: method.name,
        status: 'cancelled',
        transactionDate: DateTime.now(),
        currency: 'BDT',
        gateway: 'SSLCommerz',
      );
    }
    final result = await _ssl.pay(
      context: context,
      tranId: tranId,
      amount: amount,
      method: switch (method) {
        PaymentMethod.bkash => 'bkash',
        PaymentMethod.nagad => 'nagad',
        PaymentMethod.rocket => 'rocket',
        _ => null,
      },
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: phoneToUse,
      shippingAddress: shippingAddress,
    );

    if (result != null && result.success) {
      final payment = PaymentModel(
        id: result.tranId,
        orderId: orderId,
        amount: amount,
        method: method.name,
        status: 'successful',
        transactionDate: DateTime.now(),
        currency: 'BDT',
        gatewayTransactionId: result.bankTranId,
        gateway: 'SSLCommerz',
      );
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .set(payment.toMap());
      return payment;
    }

    return PaymentModel(
      id: tranId,
      orderId: orderId,
      amount: amount,
      method: method.name,
      status: 'failed',
      transactionDate: DateTime.now(),
      currency: 'BDT',
      gateway: 'SSLCommerz',
    );
  }

  Future<String?> _promptWalletNumber(BuildContext context,
      {required String initial, required PaymentMethod method}) async {
    // cash and online go straight to SSL without wallet prompt
    if (method == PaymentMethod.cash || method == PaymentMethod.online) {
      return initial;
    }
    final controller = TextEditingController(text: initial);
    String? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Wallet Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide ${method.name.toUpperCase()} number to proceed',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '01XXXXXXXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              result = controller.text.trim();
              Navigator.pop(ctx);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result;
  }

  // Watch the most recent payment for an order
  Stream<PaymentModel?> watchLatestPaymentForOrder(String orderId) {
    return _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .orderBy('transactionDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      return PaymentModel(
        id: data['id'] as String,
        orderId: data['orderId'] as String,
        amount: (data['amount'] as num).toDouble(),
        method: data['method'] as String,
        status: data['status'] as String,
        transactionDate: DateTime.tryParse(data['transactionDate'] as String) ??
            DateTime.now(),
        currency: (data['currency'] as String?) ?? 'BDT',
        gatewayTransactionId: data['gatewayTransactionId'] as String?,
        gateway: data['gateway'] as String?,
      );
    });
  }

  // Fetch (one-off) the most recent payment for an order
  Future<PaymentModel?> fetchLatestPaymentForOrder(String orderId) async {
    final snap = await _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .orderBy('transactionDate', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return PaymentModel(
      id: data['id'] as String,
      orderId: data['orderId'] as String,
      amount: (data['amount'] as num).toDouble(),
      method: data['method'] as String,
      status: data['status'] as String,
      transactionDate: DateTime.tryParse(data['transactionDate'] as String) ??
          DateTime.now(),
      currency: (data['currency'] as String?) ?? 'BDT',
      gatewayTransactionId: data['gatewayTransactionId'] as String?,
      gateway: data['gateway'] as String?,
    );
  }
}
