// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:medicore/config/env.dart';
import 'package:medicore/screens/shared/sslcommerz_webview.dart';

class PaymentGatewayResult {
  final bool success;
  final String status;
  final String tranId;
  final String? valId;
  final String? bankTranId;
  PaymentGatewayResult({
    required this.success,
    required this.status,
    required this.tranId,
    this.valId,
    this.bankTranId,
  });
}

class SslCommerzService {
  static const _sandboxInitUrl =
      'https://sandbox.sslcommerz.com/gwprocess/v4/api.php';
  static const _prodInitUrl =
      'https://securepay.sslcommerz.com/gwprocess/v4/api.php';

  final Dio _dio = Dio();

  Future<PaymentGatewayResult?> pay({
    required BuildContext context,
    required String tranId,
    required double amount,
    String productCategory = 'Service',
    String productName = 'MediCore Order',
    int numOfItem = 1,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? shippingAddress,
    String currency = 'BDT',
    String? method, // e.g., 'bkash', 'nagad', 'rocket'
  }) async {
    final cfg = Env.env;

    try {
      final phoneParam =
          (customerPhone).trim().isEmpty ? '01700000000' : customerPhone.trim();
      final safeName =
          (customerName).trim().isEmpty ? 'Medicore User' : customerName.trim();
      final safeEmail = (customerEmail).trim().isEmpty
          ? 'user@medicore.app'
          : customerEmail.trim();
      final initUrl = cfg.sslSandbox ? _sandboxInitUrl : _prodInitUrl;

      final form = {
        'store_id': cfg.sslStoreId,
        'store_passwd': cfg.sslStorePassword,
        'total_amount': amount.toStringAsFixed(2),
        'currency': currency,
        'tran_id': tranId,
        'success_url': cfg.successUrl,
        'fail_url': cfg.failUrl,
        'cancel_url': cfg.cancelUrl,
        'cus_name': safeName,
        'cus_email': safeEmail,
        'cus_add1': 'Dhaka',
        'cus_city': 'Dhaka',
        'cus_postcode': '1212',
        'cus_country': 'Bangladesh',
        'cus_phone': phoneParam,
        // Product details
        'product_name': productName,
        'product_category': productCategory,
        'product_profile': 'general',
        'num_of_item': numOfItem.toString(),
        // Shipping info required by SSLCommerz
        // Use 'Courier' to indicate shipment and include address
        'shipping_method': 'Courier',
        'ship_name': safeName,
        'ship_add1': (shippingAddress == null || shippingAddress.trim().isEmpty)
            ? 'Dhaka'
            : shippingAddress.trim(),
        'ship_city': 'Dhaka',
        'ship_postcode': '1212',
        'ship_country': 'Bangladesh',
      };

      // If a specific gateway is requested, hint SSLCommerz with multi_card_name
      if (method != null && method.isNotEmpty) {
        form['multi_card_name'] = method; // e.g., bkash, nagad, rocket
      }

      final res = await _dio.post(
        initUrl,
        data: FormData.fromMap(form),
        options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}),
      );

      final data = res.data is String ? jsonDecode(res.data) : res.data;
      final gatewayUrl = data['GatewayPageURL'] as String?;
      if (gatewayUrl == null || gatewayUrl.isEmpty) {
        if (kDebugMode) debugPrint('SSL init failed: $data');
        return PaymentGatewayResult(
            success: false, status: 'failed', tranId: tranId);
      }

      final result = await Navigator.of(context).push<PaymentGatewayResult>(
        MaterialPageRoute(
          builder: (_) => SslcommerzWebviewPage(
            initialUrl: gatewayUrl,
            // Pass actual URLs so the webview can intercept redirects precisely
            successUrl: cfg.successUrl,
            failUrl: cfg.failUrl,
            cancelUrl: cfg.cancelUrl,
            tranId: tranId,
          ),
        ),
      );
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('SSLCommerz error: $e');
      return PaymentGatewayResult(
          success: false, status: 'failed', tranId: tranId);
    }
  }
}
