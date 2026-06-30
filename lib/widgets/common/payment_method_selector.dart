import 'package:flutter/material.dart';
import 'package:medicore/services/payment_service.dart';

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod initial;
  final ValueChanged<PaymentMethod> onChanged;
  const PaymentMethodSelector(
      {super.key, this.initial = PaymentMethod.bkash, required this.onChanged});

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  late PaymentMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Payment Method | পেমেন্ট পদ্ধতি',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _chip(PaymentMethod.bkash, 'bKash'),
            _chip(PaymentMethod.nagad, 'Nagad'),
            _chip(PaymentMethod.rocket, 'Rocket'),
            _chip(PaymentMethod.cash, 'Cash on Delivery'),
          ],
        ),
      ],
    );
  }

  Widget _chip(PaymentMethod method, String label) {
    final selected = _selected == method;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selected = method);
        widget.onChanged(method);
      },
    );
  }
}
