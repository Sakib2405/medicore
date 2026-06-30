// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _localeKey = 'app_locale';

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isEnglish => _locale.languageCode == 'en';
  bool get isBengali => _locale.languageCode == 'bn';
  bool get isHindi => _locale.languageCode == 'hi';

  // Supported locales
  static final List<Locale> supportedLocales = [
    const Locale('en'), // English
    const Locale('bn'), // Bengali
    const Locale('hi'), // Hindi
  ];

  // Language names
  static final Map<String, String> languageNames = {
    'en': 'English',
    'bn': 'বাংলা',
    'hi': 'हिन्दी',
  };

  // Language flags (you can use emoji or image paths)
  static final Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'bn': '🇧🇩',
    'hi': '🇮🇳',
  };

  // Set locale with save functionality
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    await _saveLocale();
    notifyListeners();
  }

  // Set locale by language code
  Future<void> setLocaleByCode(String languageCode) async {
    final newLocale = Locale(languageCode);
    await setLocale(newLocale);
  }

  // Toggle between languages (for quick switching)
  Future<void> toggleLanguage() async {
    switch (_locale.languageCode) {
      case 'en':
        await setLocaleByCode('bn');
        break;
      case 'bn':
        await setLocaleByCode('hi');
        break;
      case 'hi':
        await setLocaleByCode('en');
        break;
      default:
        await setLocaleByCode('en');
    }
  }

  // Get current language name
  String get currentLanguageName {
    return languageNames[_locale.languageCode] ?? 'English';
  }

  // Get current language flag
  String get currentLanguageFlag {
    return languageFlags[_locale.languageCode] ?? '🇺🇸';
  }

  // Get language name by code
  String getLanguageName(String code) {
    return languageNames[code] ?? 'English';
  }

  // Get language flag by code
  String getLanguageFlag(String code) {
    return languageFlags[code] ?? '🇺🇸';
  }

  // Check if specific language is active
  bool isLanguageActive(String languageCode) {
    return _locale.languageCode == languageCode;
  }

  // Get current locale index
  int get currentLocaleIndex {
    return supportedLocales
        .indexWhere((locale) => locale.languageCode == _locale.languageCode);
  }

  // Set locale by index
  Future<void> setLocaleByIndex(int index) async {
    if (index >= 0 && index < supportedLocales.length) {
      await setLocale(supportedLocales[index]);
    }
  }

  // Load locale from shared preferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      if (savedLocale != null) {
        _locale = Locale(savedLocale);
      } else {
        // Default to device locale if supported, otherwise English
        final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        if (supportedLocales.any(
            (locale) => locale.languageCode == deviceLocale.languageCode)) {
          _locale = deviceLocale;
        } else {
          _locale = const Locale('en');
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading locale: $e');
      _locale = const Locale('en');
    }
  }

  // Save locale to shared preferences
  Future<void> _saveLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, _locale.languageCode);
    } catch (e) {
      print('Error saving locale: $e');
    }
  }

  // Reset to system locale
  Future<void> resetToSystem() async {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (supportedLocales
        .any((locale) => locale.languageCode == systemLocale.languageCode)) {
      await setLocale(systemLocale);
    } else {
      await setLocale(const Locale('en'));
    }
  }

  // Get locale for MaterialApp
  Locale? getMaterialAppLocale() {
    return _locale;
  }

  // Check if RTL (Right-to-Left) language
  bool get isRTL {
    return _locale.languageCode == 'ar' || _locale.languageCode == 'ur';
  }

  // Get text direction
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }

  // Language change callback with context (for showing dialogs etc.)
  Future<void> changeLanguageWithDialog(
      BuildContext context, String languageCode) async {
    final newLocale = Locale(languageCode);

    // Show loading or confirmation dialog if needed
    // For now, just change the locale
    await setLocale(newLocale);

    // Optional: Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to ${getLanguageName(languageCode)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
