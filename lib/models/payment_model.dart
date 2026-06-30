class PaymentModel {
  final String id;
  final String orderId;
  final double amount;
  final String method; // e.g., 'bkash', 'nagad', 'rocket', 'cash'
  final String status; // e.g., 'successful', 'failed', 'cancelled'
  final DateTime transactionDate;
  final String currency; // e.g., 'BDT'
  final String? gatewayTransactionId; // SSLC bank_tran_id
  final String? gateway; // 'SSLCommerz'

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.transactionDate,
    this.currency = 'BDT',
    this.gatewayTransactionId,
    this.gateway,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'amount': amount,
        'method': method,
        'status': status,
        'transactionDate': transactionDate.toIso8601String(),
        'currency': currency,
        'gatewayTransactionId': gatewayTransactionId,
        'gateway': gateway,
      };
}
