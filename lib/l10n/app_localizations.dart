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
      // Cart page
      'cart':'Cart',
      'items':'items',
      'proceedToCheckout':'Proceed to checkout',
      // Sign-in page
      'signIn':'Sign-In',
      'signInToYourProfile':'Sign in to your profile',
      'underTitle':'To order, do authorization first',
      'phoneNumberButton':'Enter your phone number',
      'privacyPolicy':'Privacy policy',
      // Authorization page
      'authorization':'Authorization',
      'authorizationTitle':'Please enter your details\nto log in the application',
      'firstNameHintText':'Enter your first name',
      'numberHintText':'Enter phone number',
      'continueButton':'Continue',

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
      'totalPrice':'Umumiy',
      'addToCart':'Savatchaga qo\'shish',
      // Cart page
      'cart':'Savatcha',
      'items':'dona',
      'proceedToCheckout':'To\'lovga o\'tish',
      // Sign-in page
      'signIn':'Kirish',
      'signInToYourProfile':'Profilga kirish',
      'underTitle':'Buyurtma uchun avval avtorizatsiyadan o\'ting',
      'phoneNumberButton':'Telefon raqamingizni kiriting',
      'privacyPolicy':'Maxfiylik siyosati',
      // Authorization page
      'authorization':'Avtorizatsiya',
      'authorizationTitle':'Ilovaga kirish uchun ma\'lumotlaringizni kiriting',
      'firstNameHintText':'Ismingizni kiriting',
      'numberHintText':'Telefon raqamingiz',
      'continueButton':'Davom etish',
      
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
  // Cart page
  String get cart => _localizedValues[locale.languageCode]!['cart']!;
  String get items => _localizedValues[locale.languageCode]!['items']!;
  String get proceedToCheckout => _localizedValues[locale.languageCode]!['proceedToCheckout']!;
  // Sign-in page
  String get signIn => _localizedValues[locale.languageCode]!['signIn']!;
  String get signInToYourProfile => _localizedValues[locale.languageCode]!['signInToYourProfile']!;
  String get underTitle => _localizedValues[locale.languageCode]!['underTitle']!;
  String get phoneNumberButton => _localizedValues[locale.languageCode]!['phoneNumberButton']!;
  String get privacyPolicy => _localizedValues[locale.languageCode]!['privacyPolicy']!;
  // Authorization page
  String get authorization => _localizedValues[locale.languageCode]!['authorization']!;
  String get authorizationTitle => _localizedValues[locale.languageCode]!['authorizationTitle']!;
  String get firstNameHintText => _localizedValues[locale.languageCode]!['firstNameHintText']!;
  String get numberHintText => _localizedValues[locale.languageCode]!['numberHintText']!;
  String get continueButton => _localizedValues[locale.languageCode]!['continueButton']!;


  
  





}