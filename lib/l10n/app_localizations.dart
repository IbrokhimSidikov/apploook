import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'hello': 'Hello',
      'welcome': 'Welcome to our app',
      'settings': 'Settings',
      'language': 'Language',
      'notification':'Notification will appear here',
      // Profile page
      'logout':'Log out',
      'deleteAccount':'Delete Account',
      // Details page
      'totalPrice':'Total Price',
      'addToCart':'Add to cart',
    },
    'uz': {
      'hello': 'Salom',
      'welcome': 'Ilovamizga xush kelibsiz',
      'settings': 'Sozlamalar',
      'language': 'Til',
      'notification':'Sizning xabarnomalaringiz bu yerda korinadi',
      // Profile page
      'logout':'Chiqish',
      'deleteAccount':'Hisobni o\'chirish',
      // Details page
      'totalPrice':'Umumiy Qiymat',
      'addToCart':'Savatchaga qo\'shish',

    }
  };

  String get hello => _localizedValues[locale.languageCode]!['hello']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get notification => _localizedValues[locale.languageCode]!['notification']!;
  // Profile page
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get deleteAccount => _localizedValues[locale.languageCode]!['deleteAccount']!;
  // Details page
  String get totalPrice => _localizedValues[locale.languageCode]!['totalPrice']!;
  String get addToCart => _localizedValues[locale.languageCode]!['addToCart']!;





}