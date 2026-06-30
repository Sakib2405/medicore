import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:medicore/services/sslcommerz_service.dart';

class SslcommerzWebviewPage extends StatefulWidget {
  final String initialUrl;
  final String? successUrl;
  final String? failUrl;
  final String? cancelUrl;
  final String tranId;

  const SslcommerzWebviewPage({
    super.key,
    required this.initialUrl,
    this.successUrl,
    this.failUrl,
    this.cancelUrl,
    required this.tranId,
  });

  @override
  State<SslcommerzWebviewPage> createState() => _SslcommerzWebviewPageState();
}

class _SslcommerzWebviewPageState extends State<SslcommerzWebviewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _completed = false;

  void _popResult(PaymentGatewayResult result) {
    if (_completed || !mounted) return;
    _completed = true;
    Navigator.of(context).pop(result);
  }

  bool _looksLikeSuccess(Uri uri) {
    final url = uri.toString().toLowerCase();
    final qp = uri.queryParameters;
    final status = (qp['status'] ?? qp['Status'] ?? '').toLowerCase();
    final valId = qp['val_id'] ?? qp['val_Id'] ?? '';

    // Exact match against the configured success URL
    if (widget.successUrl != null &&
        uri.toString().startsWith(widget.successUrl!)) {
      return true;
    }
    // Path pattern
    if (uri.path.toLowerCase().endsWith('/success')) return true;
    if (uri.pathSegments.any((s) => s.toLowerCase() == 'success')) return true;

    // SSLCommerz query param patterns (both on their domain and redirect)
    if (status == 'success' || status == 'validated' || status == 'valid') {
      return true;
    }
    // SSLCommerz sandbox: URL contains 'VALID' or 'validated' result page
    if (url.contains('sslcommerz') &&
        (url.contains('valid') || qp.containsKey('val_id'))) {
      if (!url.contains('fail') && !url.contains('cancel')) return true;
    }
    // val_id present with a non-fail/cancel status = validated payment
    if (valId.isNotEmpty &&
        (status.isEmpty ||
            (!status.contains('fail') &&
                !status.contains('cancel') &&
                !status.contains('unattempt')))) {
      return true;
    }
    return false;
  }

  bool _looksLikeFailure(Uri uri) {
    final url = uri.toString();
    final qp = uri.queryParameters;
    final status = (qp['status'] ?? '').toLowerCase();
    if (widget.failUrl != null && url.startsWith(widget.failUrl!)) return true;
    if (uri.path.toLowerCase().endsWith('/fail')) return true;
    if (uri.pathSegments.any((s) => s.toLowerCase() == 'fail')) return true;
    if (status.contains('fail') || status == 'failed') return true;
    return false;
  }

  bool _looksLikeCancel(Uri uri) {
    final url = uri.toString();
    final qp = uri.queryParameters;
    final status = (qp['status'] ?? '').toLowerCase();
    if (widget.cancelUrl != null && url.startsWith(widget.cancelUrl!)) {
      return true;
    }
    if (uri.path.toLowerCase().endsWith('/cancel')) return true;
    if (uri.pathSegments.any((s) => s.toLowerCase() == 'cancel')) return true;
    if (status.contains('cancel') || status == 'unattempted') return true;
    return false;
  }

  void _handleUrl(String url) {
    if (_completed) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (_looksLikeSuccess(uri)) {
      final qp = uri.queryParameters;
      _popResult(PaymentGatewayResult(
        success: true,
        status: (qp['status'] ?? 'success'),
        tranId: widget.tranId,
        valId: qp['val_id'],
        bankTranId: qp['bank_tran_id'],
      ));
      return;
    }
    if (_looksLikeFailure(uri)) {
      _popResult(PaymentGatewayResult(
        success: false,
        status: 'failed',
        tranId: widget.tranId,
      ));
      return;
    }
    if (_looksLikeCancel(uri)) {
      _popResult(PaymentGatewayResult(
        success: false,
        status: 'cancelled',
        tranId: widget.tranId,
      ));
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          _handleUrl(request.url);
          if (_completed) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          // Catch URL as early as possible — before page body loads
          _handleUrl(url);
        },
        onPageFinished: (url) async {
          if (mounted) setState(() => _loading = false);
          _handleUrl(url);
          // Also check currentUrl in case the reported URL differs
          try {
            final current = await _controller.currentUrl();
            if (current != null) _handleUrl(current);
          } catch (_) {}
        },
        onWebResourceError: (error) async {
          // Page load failed (e.g., medicore.app/success is unreachable) —
          // still check the URL so we can detect the success/fail pattern.
          try {
            final current = await _controller.currentUrl();
            if (current != null) _handleUrl(current);
          } catch (_) {}
        },
      ))
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popResult(PaymentGatewayResult(
          success: false,
          status: 'cancelled',
          tranId: widget.tranId,
        ));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          actions: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () {
                _popResult(PaymentGatewayResult(
                  success: false,
                  status: 'cancelled',
                  tranId: widget.tranId,
                ));
              },
            )
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
