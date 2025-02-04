import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = false;
  bool _showOtpField = false;
  final TextEditingController _otpController = TextEditingController();
  String? _verifiedPhoneNumber;

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

  Future<void> _sendOtp() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    final phone = _phoneNumber?.international ?? '';
    if (!phone.startsWith('+998')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Only Uzbekistan (+998) numbers are allowed.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      setState(() {
        _showOtpField = true;
        _verifiedPhoneNumber = phone;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _verifiedPhoneNumber == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: _verifiedPhoneNumber!,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );
      _onAuthenticationSuccess();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP! Please try again.")),
      );
    }
  }

  void _onAuthenticationSuccess() async {
    await _savePhoneNumber(
      _phoneNumber?.international ?? '+998',
      _firstNameController.text,
    );
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/homeNew');
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
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 75),
          Center(
            child: Text(
              AppLocalizations.of(context).authorizationTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
          const SizedBox(height: 40.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).nameTranslation,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 255, 215, 56),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Form(
              key: _phoneFormKey,
              child: PhoneFormField(
                initialValue: _phoneNumber ??
                    const PhoneNumber(isoCode: IsoCode.UZ, nsn: ''),
                validator: PhoneValidator.compose([
                  PhoneValidator.required(context),
                  PhoneValidator.validMobile(context),
                ]),
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).phoneNumberTranslation,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 255, 215, 56),
                    ),
                  ),
                ),
                onChanged: (PhoneNumber? phoneNumber) {
                  setState(() {
                    _phoneNumber = phoneNumber;
                    _isPhoneNumberValid =
                        _phoneFormKey.currentState?.validate() ?? false;
                  });
                },
                onSaved: (PhoneNumber? phoneNumber) {
                  _phoneNumber = phoneNumber;
                },
              ),
            ),
          ),
          if (_showOtpField) ...[
            const SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 255, 215, 56),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ),
          ],
          const Spacer(),
          if (_isLoading)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 255, 215, 56),
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 50.0, left: 20.0, right: 20.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _showOtpField
                        ? _verifyOtp
                        : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 215, 56),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 40.0,
                    right: 40.0,
                    top: 10.0,
                    bottom: 10.0,
                  ),
                  child: Text(
                    _showOtpField
                        ? 'Verify OTP'
                        : AppLocalizations.of(context).continueButton,
                    style: const TextStyle(fontSize: 20, color: Colors.black),
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
