import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'whatsNew': 'WHAT\'S NEW',
      'hello': 'Hello',
      'welcome': 'Welcome to our app',
      'settings': 'Settings',
      'language': 'Language',
      'notification': 'Notification will appear here',
      'noNotifications': 'No notifications yet',
      // Profile page
      'logout': 'Log out',
      'deleteAccount': 'Delete Account',
      'confirmDelete': 'Confirm Delete',
      'confirmDialog': 'Are you sure you want to delete your account?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      // Details page
      'totalPrice': 'Total Price',
      'addToCart': 'Add to cart',
      // Cart page
      'cart': 'Cart',
      'items': 'items',
      'proceedToCheckout': 'Proceed to checkout',
      // Sign-in page
      'signIn': 'Sign-In',
      'signInToYourProfile': 'Sign in to your profile',
      'underTitle': 'To order, do authorization first',
      'phoneNumberButton': 'Enter your phone number',
      'privacyPolicy': 'Privacy Policy',
      'accept': 'Accept',
      'decline': 'Decline',
      'privacyPolicyContent':
          'Introduction\n\nOur privacy policy will help you understand what information we collect at Loook, how Loook uses it, and what choices you have.\nLoook built the Loook app as a free app. This SERVICE is provided by Loook at no cost and is intended for use as is.\nIf you choose to use our Service, then you agree to the collection and use of information in relation with this policy.\nThe Personal Information that we collect are used for providing and improving the Service.\nWe will not use or share your information with anyone except as described in this Privacy Policy.\n\n\nContact Information:\nEmail: loook.uz.tech@gmail.com',
      // Authorization page
      'authorization': 'Authorization',
      'authorizationTitle':
          'Please enter your details\nto log in the application',
      'firstNameHintText': 'Enter your first name',
      'numberHintText': 'Enter phone number',
      'continueButton': 'Continue',
      'phoneNumberTranslation': 'Phone number',
      'nameTranslation': 'Name',
      // Checkout page
      'checkout': 'Checkout',
      'chooseOrderType': 'Choose your order type',
      'delivery': 'DELIVERY',
      'selfPickup': 'SELF-PICKUP',
      'selfPickupTitle': 'Which store would you like to pick from?',
      'yourDeliveryLocation': 'Your Delivery Location!',
      'chooseYourLocation': 'Choose your location -->',
      'chooseBranchToPick': 'Choose branch to pick up',
      'selectBranch': 'Select Branch',
      'orderPrice': 'Order Price',
      'deliveryPrice': 'Delivery Price',
      'unknown': 'Unknown',
      'paymentMethod': 'Payment Method',
      'cash': 'Cash',
      'card': 'Card',
      'additionalNumber': 'Additional Number',
      'comments': 'Comments',
      'order': 'Order',
      'orderSuccess': 'Order Success',
      'orderSuccessSubTitle': 'Your order has been placed successfully!',
      'carhopService': 'Please select your LOOOK Carhop store:',
      'carhopServiceBranchInfo': 'Park your car in the area of:',
      'carDetails': 'Your car details:',
      'selectRegion': 'Select Region',
      'openingHours': 'Opening Hours',
      'viewInMap': 'View in Map',
      'carDetailsHint': 'e.g: 01|A712AA Black Chevrolet Gentra',
      'carDetailsInputHint': 'Please share - your car no. color and model',
      // Notifications
      'notifications': 'Notifications',
      'notificationsPlaceholder': 'Notifications will appear here',
      // Notifications view
      'orderNumber': 'Order #',
      'arrived': 'Arrived',
      'totalAmount': 'Total Amount',
      'currency': 'UZS',
      // Map Screen
      'confirmAddress': 'Do you confirm your address?',
      'confirm': 'Confirm',
      'save': 'Save',
      'yourLocation': 'Your Location',
      'selectedAddress': 'Your selected address',
      // Verification screen
      'verification': 'Verification',
      'verificationTitle':
          'Please enter the 4-digit code\nto verify your phone number',
      'invalidCodeMessage': 'Invalid verification code',
      'validCodeMessage': 'Verification successful',
      'arrivedButtonHint':
          'Tap when you arrive at the car parking zone to notify the restaurant',
      'arrivedButtonTooltip': 'Let the restaurant know you\'re here!',
    },
    'uz': {
      'whatsNew': 'YANGILIKLAR',
      'hello': 'Salom',
      'welcome': 'Ilovamizga xush kelibsiz',
      'settings': 'Sozlamalar',
      'language': 'Til',
      'notification': 'Sizning xabarnomalaringiz bu yerda korinadi',
      'noNotifications': 'Hozircha Xabarnomalar yo\'q',

      // Profile page
      'logout': 'Chiqish',
      'deleteAccount': 'Hisobni o\'chirish',
      'confirmDelete': 'O\'chirishni tasdiqlang',
      'confirmDialog':
          'Hisobingizni o\'chirishni xohlayotganingizga aminmisiz?',
      'cancel': 'Bekor qilish',
      'delete': 'O\'chirish',
      // Details page
      'totalPrice': 'Umumiy',
      'addToCart': 'Qo\'shish',
      // Cart page
      'cart': 'Savatcha',
      'items': 'dona',
      'proceedToCheckout': 'To\'lovga o\'tish',
      // Sign-in page
      'signIn': 'Kirish',
      'signInToYourProfile': 'Profilga kirish',
      'underTitle': 'Buyurtma uchun avval avtorizatsiyadan o\'ting',
      'phoneNumberButton': 'Telefon raqamingizni kiriting',
      'privacyPolicy': 'Maxfiylik siyosati',
      'accept': 'Qabul qilish',
      'decline': 'Rad etish',
      'privacyPolicyContent':
          'Kirish\n\nBizning maxfiylik siyosatimiz Loook-da qanday ma\'lumotlarni to\'plashimiz, Loook ulardan qanday foydalanishi va sizda qanday tanlovlar borligini tushunishga yordam beradi.\nLoook Loook ilovasini bepul ilova sifatida yaratdi. Ushbu XIZMAT Loook tomonidan bepul taqdim etiladi va mavjud bo\'lganicha foydalanish uchun mo\'ljallangan.\nAgar siz bizning Xizmatimizdan foydalanishni tanlasangiz, u holda siz ushbu siyosatga muvofiq ma\'lumotlarni to\'plash va ulardan foydalanishga rozilik bildirasiz.\nBiz to\'playdigan shaxsiy ma\'lumotlar Xizmatni taqdim etish va takomillashtirish uchun ishlatiladi.\nBiz sizning ma\'lumotlaringizni ushbu Maxfiylik siyosatida tavsiflangan holatlardan tashqari hech kim bilan almashmaymiz yoki baham ko\'rmaymiz.\n\n\nAloqa ma\'lumotlari:\nEmail: loook.uz.tech@gmail.com',
      // Authorization page
      'authorization': 'Avtorizatsiya',
      'authorizationTitle':
          'Ilovaga kirish uchun\nma\'lumotlaringizni kiriting',
      'firstNameHintText': 'Ismingizni kiriting',
      'numberHintText': 'Telefon raqamingiz',
      'continueButton': 'Davom etish',
      'phoneNumberTranslation': 'Phone number',
      'nameTranslation': 'Name',
      // Checkout page
      'checkout': 'Buyurtmani rasmiylashtirish',
      'chooseOrderType': 'Buyurtma turini tanlang',
      'delivery': 'YETKAZISH',
      'selfPickup': 'OLIB KETISH',
      'selfPickupTitle': 'Olib ketish uchun filial tanlang',
      'yourDeliveryLocation': 'Yetkazish manzilingiz!',
      'chooseYourLocation': 'Xaritadan tanlang -->',
      'chooseBranchToPick': 'Olib ketish uchun',
      'selectBranch': 'Filial tanlang',
      'orderPrice': 'Buyurtma qiymati',
      'deliveryPrice': 'Yetkazib berish narxi',
      'unknown': 'Noma\'lum',
      'paymentMethod': 'To\'lov usuli',
      'cash': 'Naxt',
      'card': 'Karta',
      'additionalNumber': 'Qo\'shimcha telefon raqami',
      'comments': 'Izohlar',
      'order': 'Buyurtma',
      'orderSuccess': 'Buyurtma qabul qilindi',
      'orderSuccessSubTitle': 'Sizning buyurtmangiz qabul qilindi!',
      'carhopService': 'LOOOK Carhop filialini tanlang:',
      'carhopServiceBranchInfo': 'Avtomobilingizni quyidagi hududga qo\'ying:',
      'carDetails': 'Avtomobilingiz tafsilotlari:',
      'selectRegion': 'Shaxar tanlang',
      'openingHours': 'Ishlash vaqti',
      'viewInMap': 'Xaritadan ko\'rish',
      'carDetailsHint': 'e.g: 01|A712AA Qora Chevrolet Gentra',
      'carDetailsInputHint':
          'Iltimos - Avtomobil raqami, rangi, rusumini kiriting',
      // Notifications
      'notifications': 'Xabarnoma',
      'notificationsPlaceholder': 'Xabarlaringiz shu yerda ko\'rinadi',
      // Notifications view
      'orderNumber': 'Buyurtma #',
      'arrived': 'Yetib keldim',
      'totalAmount': 'Umumiy summa',
      'currency': 'UZS',
      // Map Screen
      'confirmAddress': 'Manzilingizni Tasdiqlaysizmi?',
      'confirm': 'Tasdiqlash',
      'save': 'Saqlash',
      'yourLocation': 'Sizning Manzilingiz',
      'selectedAddress': 'Siz tanlagan manzil',
      // Verification screen
      'verification': 'Tasdiqlash',
      'verificationTitle':
          'Telefon raqamingizni tasdiqlash uchun\n4 xonali kodni kiriting',
      'invalidCodeMessage': 'Noto\'g\'ri kod',
      'validCodeMessage': 'Tasdiqlandi',
      'arrivedButtonHint':
          'Avtomobil to\'xtash joyiga yetib kelganingizda, restorantni xabardor qilish uchun bosing',
      'arrivedButtonTooltip': 'Restoranga kelganingizni bildiring!',
    }
  };
  String get whatsNew => _localizedValues[locale.languageCode]!['whatsNew']!;
  String get hello => _localizedValues[locale.languageCode]!['hello']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get notification =>
      _localizedValues[locale.languageCode]!['notification']!;
  String get noNotifications =>
      _localizedValues[locale.languageCode]!['noNotifications']!;

  // Profile page
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get deleteAccount =>
      _localizedValues[locale.languageCode]!['deleteAccount']!;
  String get confirmDelete =>
      _localizedValues[locale.languageCode]!['confirmDelete']!;
  String get confirmDialog =>
      _localizedValues[locale.languageCode]!['confirmDialog']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;

  // Details page
  String get totalPrice =>
      _localizedValues[locale.languageCode]!['totalPrice']!;
  String get addToCart => _localizedValues[locale.languageCode]!['addToCart']!;

  // Cart page
  String get cart => _localizedValues[locale.languageCode]!['cart']!;
  String get items => _localizedValues[locale.languageCode]!['items']!;
  String get proceedToCheckout =>
      _localizedValues[locale.languageCode]!['proceedToCheckout']!;

  // Sign-in page
  String get signIn => _localizedValues[locale.languageCode]!['signIn']!;
  String get signInToYourProfile =>
      _localizedValues[locale.languageCode]!['signInToYourProfile']!;
  String get underTitle =>
      _localizedValues[locale.languageCode]!['underTitle']!;
  String get phoneNumberButton =>
      _localizedValues[locale.languageCode]!['phoneNumberButton']!;
  String get privacyPolicy =>
      _localizedValues[locale.languageCode]!['privacyPolicy']!;
  String get accept => _localizedValues[locale.languageCode]!['accept']!;
  String get decline => _localizedValues[locale.languageCode]!['decline']!;
  String get privacyPolicyContent =>
      _localizedValues[locale.languageCode]!['privacyPolicyContent']!;

  // Authorization page
  String get authorization =>
      _localizedValues[locale.languageCode]!['authorization']!;
  String get authorizationTitle =>
      _localizedValues[locale.languageCode]!['authorizationTitle']!;
  String get firstNameHintText =>
      _localizedValues[locale.languageCode]!['firstNameHintText']!;
  String get numberHintText =>
      _localizedValues[locale.languageCode]!['numberHintText']!;
  String get continueButton =>
      _localizedValues[locale.languageCode]!['continueButton']!;
  String get phoneNumberTranslation =>
      _localizedValues[locale.languageCode]!['phoneNumberTranslation']!;
  String get nameTranslation =>
      _localizedValues[locale.languageCode]!['nameTranslation']!;

  // Chekout page
  String get checkout => _localizedValues[locale.languageCode]!['checkout']!;
  String get chooseOrderType =>
      _localizedValues[locale.languageCode]!['chooseOrderType']!;
  String get delivery => _localizedValues[locale.languageCode]!['delivery']!;
  String get selfPickup =>
      _localizedValues[locale.languageCode]!['selfPickup']!;
  String get selfPickupTitle =>
      _localizedValues[locale.languageCode]!['selfPickupTitle']!;
  String get yourDeliveryLocation =>
      _localizedValues[locale.languageCode]!['yourDeliveryLocation']!;
  String get chooseYourLocation =>
      _localizedValues[locale.languageCode]!['chooseYourLocation']!;
  String get chooseBranchToPick =>
      _localizedValues[locale.languageCode]!['chooseBranchToPick']!;
  String get selectBranch =>
      _localizedValues[locale.languageCode]!['selectBranch']!;
  String get orderPrice =>
      _localizedValues[locale.languageCode]!['orderPrice']!;
  String get deliveryPrice =>
      _localizedValues[locale.languageCode]!['deliveryPrice']!;
  String get unknown => _localizedValues[locale.languageCode]!['unknown']!;
  String get paymentMethod =>
      _localizedValues[locale.languageCode]!['paymentMethod']!;
  String get cash => _localizedValues[locale.languageCode]!['cash']!;
  String get card => _localizedValues[locale.languageCode]!['card']!;
  String get additionalNumber =>
      _localizedValues[locale.languageCode]!['additionalNumber']!;
  String get comments => _localizedValues[locale.languageCode]!['comments']!;
  String get order => _localizedValues[locale.languageCode]!['order']!;
  String get orderSuccess =>
      _localizedValues[locale.languageCode]!['orderSuccess']!;
  String get orderSuccessSubTitle =>
      _localizedValues[locale.languageCode]!['orderSuccessSubTitle']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get notificationsPlaceholder =>
      _localizedValues[locale.languageCode]!['notificationsPlaceholder']!;
  String get carhopService =>
      _localizedValues[locale.languageCode]!['carhopService']!;
  String get carhopServiceBranchInfo =>
      _localizedValues[locale.languageCode]!['carhopServiceBranchInfo']!;
  String get carDetails =>
      _localizedValues[locale.languageCode]!['carDetails']!;
  String get selectRegion =>
      _localizedValues[locale.languageCode]!['selectRegion']!;
  String get openingHours =>
      _localizedValues[locale.languageCode]!['openingHours']!;
  String get viewInMap => _localizedValues[locale.languageCode]!['viewInMap']!;
  String get carDetailsHint =>
      _localizedValues[locale.languageCode]!['carDetailsHint']!;
  String get carDetailsInputHint =>
      _localizedValues[locale.languageCode]!['carDetailsInputHint']!;

  // Map screen
  String get confirmAddress =>
      _localizedValues[locale.languageCode]!['confirmAddress']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get yourLocation =>
      _localizedValues[locale.languageCode]!['yourLocation']!;
  String get selectedAddress =>
      _localizedValues[locale.languageCode]!['selectedAddress']!;

  // Verification
  String get verification =>
      _localizedValues[locale.languageCode]!['verification']!;
  String get verificationTitle =>
      _localizedValues[locale.languageCode]!['verificationTitle']!;
  String get invalidCodeMessage =>
      _localizedValues[locale.languageCode]!['invalidCodeMessage']!;
  String get validCodeMessage =>
      _localizedValues[locale.languageCode]!['validCodeMessage']!;

  // Notifications view
  String get orderNumber =>
      _localizedValues[locale.languageCode]!['orderNumber']!;
  String get arrived => _localizedValues[locale.languageCode]!['arrived']!;
  String get totalAmount =>
      _localizedValues[locale.languageCode]!['totalAmount']!;
  String get currency => _localizedValues[locale.languageCode]!['currency']!;
  String get arrivedButtonHint =>
      _localizedValues[locale.languageCode]!['arrivedButtonHint']!;
  String get arrivedButtonTooltip =>
      _localizedValues[locale.languageCode]!['arrivedButtonTooltip']!;
}
