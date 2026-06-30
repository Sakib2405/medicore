import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Environment {
  final String geminiApiKey;
  final String geminiProxyUrl;
  final String sslStoreId;
  final String sslStorePassword;
  final bool sslSandbox;
  final String successUrl;
  final String failUrl;
  final String cancelUrl;

  Environment({
    required this.geminiApiKey,
    required this.geminiProxyUrl,
    required this.sslStoreId,
    required this.sslStorePassword,
    required this.sslSandbox,
    required this.successUrl,
    required this.failUrl,
    required this.cancelUrl,
  });
}

class Env {
  static late final Environment env;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env", mergeWith: {});
    } catch (_) {
      // .env file may not exist in web production builds
    }
    String normalizeUrl(String? value, String fallback) {
      final raw = (value ?? '').trim();
      if (raw.isEmpty) return fallback;
      // Collapse any extra slashes after scheme, e.g. https:////host -> https://host
      final schemeMatch =
          RegExp(r'^(https?:)/*', caseSensitive: false).firstMatch(raw);
      String fixed = raw;
      if (schemeMatch != null) {
        final scheme = schemeMatch.group(1)!;
        final rest = raw.substring(schemeMatch.end);
        fixed = '$scheme//$rest';
      } else if (raw.startsWith('//')) {
        fixed = 'https:$raw';
      } else if (!raw.contains('://')) {
        fixed = 'https://$raw';
      }
      final uri = Uri.tryParse(fixed);
      if (uri == null || !(uri.hasScheme && uri.hasAuthority)) {
        return fallback;
      }
      return fixed;
    }

    final webOriginFallback = kIsWeb ? Uri.base.origin : 'https://medicore.app';

    // dart-define values (injected at build time for web/CI, empty string if not set)
    const geminiKeyDefine = String.fromEnvironment('GEMINI_API_KEY');
    const geminiProxyDefine = String.fromEnvironment('GEMINI_PROXY_URL');
    const sslStoreIdDefine = String.fromEnvironment('SSL_STORE_ID');
    const sslStorePassDefine = String.fromEnvironment('SSL_STORE_PASSWORD');
    const sslSandboxDefine = String.fromEnvironment('SSL_SANDBOX');
    const successUrlDefine = String.fromEnvironment('SSL_SUCCESS_URL');
    const failUrlDefine = String.fromEnvironment('SSL_FAIL_URL');
    const cancelUrlDefine = String.fromEnvironment('SSL_CANCEL_URL');

    env = Environment(
      geminiApiKey: geminiKeyDefine.isNotEmpty
          ? geminiKeyDefine
          : (dotenv.maybeGet('GEMINI_API_KEY') ?? ''),
      geminiProxyUrl: geminiProxyDefine.isNotEmpty
          ? geminiProxyDefine
          : (dotenv.maybeGet('GEMINI_PROXY_URL') ?? ''),
      sslStoreId: sslStoreIdDefine.isNotEmpty
          ? sslStoreIdDefine
          : (dotenv.maybeGet('SSL_STORE_ID') ?? ''),
      sslStorePassword: sslStorePassDefine.isNotEmpty
          ? sslStorePassDefine
          : (dotenv.maybeGet('SSL_STORE_PASSWORD') ?? ''),
      sslSandbox: sslSandboxDefine.isNotEmpty
          ? sslSandboxDefine.toLowerCase() == 'true'
          : dotenv.get('SSL_SANDBOX', fallback: 'true').toLowerCase() == 'true',
      successUrl: normalizeUrl(
          successUrlDefine.isNotEmpty ? successUrlDefine : dotenv.maybeGet('SSL_SUCCESS_URL'),
          '$webOriginFallback/success'),
      failUrl: normalizeUrl(
          failUrlDefine.isNotEmpty ? failUrlDefine : dotenv.maybeGet('SSL_FAIL_URL'),
          '$webOriginFallback/fail'),
      cancelUrl: normalizeUrl(
          cancelUrlDefine.isNotEmpty ? cancelUrlDefine : dotenv.maybeGet('SSL_CANCEL_URL'),
          '$webOriginFallback/cancel'),
    );
  }
}
