import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?)
        ?.cast<String, dynamic>();
    final uri = Uri.base; // Web deep link fallback
    final status = (args?['status'] as String?) ??
        uri.queryParameters['status'] ??
        'success';
    final tranId =
        (args?['tranId'] as String?) ?? uri.queryParameters['tran_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                status == 'success'
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 96,
                color: status == 'success' ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                status == 'success' ? 'Payment Successful' : 'Payment Failed',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (tranId != null)
                Text(
                  'Transaction ID: $tranId',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    Routes.pushNamedAndRemoveUntil(context, Routes.patientHome),
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
