import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  // Initialize and load saved locale
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language');
    
    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  // Set locale and persist to SharedPreferences
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', locale.languageCode);
    
    notifyListeners();
  }
}
