import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authorization extends StatefulWidget {
  const Authorization({super.key});

  @override
  State<Authorization> createState() => _AuthorizationState();
}

class _AuthorizationState extends State<Authorization> {
  PhoneNumber? _phoneNumber;
  final _phoneFormKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  bool _isPhoneNumberValid = false;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber') ?? '+998';
    final firstName = prefs.getString('firstName') ?? '';
    setState(() {
      _phoneNumber = PhoneNumber.parse(phoneNumber);
      _firstNameController.text = firstName;
    });
  }

  Future<void> _savePhoneNumber(String phoneNumber, String firstName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phoneNumber', phoneNumber);
    await prefs.setString('firstName', firstName);
  }

  void _continue() {
    if (_phoneFormKey.currentState?.validate() ?? false) {
      _savePhoneNumber(
          _phoneNumber?.international ?? '+998', _firstNameController.text);

      Navigator.pushReplacementNamed(context, '/homeNew');
      ;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context).authorization,
          style: TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 75),
           Center(
            child: Text(
              AppLocalizations.of(context).authorizationTitle,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20.0),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).firstNameHintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context).firstNameHintText;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20.0),
          Padding(
            padding: const EdgeInsets.only(left:20, right: 20),
            child: Form(
              key: _phoneFormKey,
              child: PhoneFormField(
                initialValue:
                    _phoneNumber ?? PhoneNumber(isoCode: IsoCode.UZ, nsn: ''),
                validator: PhoneValidator.compose([
                  PhoneValidator.required(context),
                  PhoneValidator.validMobile(context),
                ]),
                enabled: true,
                isCountrySelectionEnabled: false,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).numberHintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (phoneNumber) {
                  setState(() {
                    _phoneNumber = phoneNumber;
                    _isPhoneNumberValid =
                        _phoneFormKey.currentState?.validate() ?? false;
                  });
                },
                countryButtonStyle: const CountryButtonStyle(
                  showDialCode: true, // Display +998
                  showIsoCode: false, // Hide ISO code
                  showFlag: true, // Display Uzbekistan flag
                  flagSize: 16,
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, left: 20.0, right: 20.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: _isPhoneNumberValid ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 215, 56),
                ),
                child:  Padding(
                  padding: EdgeInsets.only(
                      left: 40.0, right: 40.0, top: 10.0, bottom: 10.0),
                  child: Text(
                    AppLocalizations.of(context).continueButton,
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
