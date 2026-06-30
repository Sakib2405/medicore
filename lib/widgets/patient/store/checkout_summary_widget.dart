import 'package:flutter/material.dart';
import 'package:medicore/utils/currency.dart';

class CheckoutSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double total;

  const CheckoutSummaryWidget({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('Shipping', shipping),
            const Divider(height: 24),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    final style = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(CurrencyFormatter.taka(amount), style: style),
      ],
    );
  }
}
