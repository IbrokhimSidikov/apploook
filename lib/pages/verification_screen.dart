// lib/pages/verification_screen.dart
import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String firstName;

  const VerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.firstName,
  }) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phoneNumber', widget.phoneNumber);
    await prefs.setString('firstName', widget.firstName);
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 4) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyCode(
        widget.phoneNumber,
        _codeController.text.trim(),
      );

      if (mounted) {
        if (response['status_code'] == 200) {
          // Save credentials only after successful verification
          await _saveUserData();
          Navigator.pushReplacementNamed(context, '/homeNew');
        } else {
          _codeController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Verification failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context).verification,
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
          Text(
            AppLocalizations.of(context).verificationTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _codeController,
              onChanged: (value) {},
              onCompleted: (value) => _verifyCode(),
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                activeColor: const Color.fromARGB(255, 255, 215, 56),
                selectedColor: const Color.fromARGB(255, 255, 215, 56),
                inactiveColor: Colors.grey,
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 255, 215, 56),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
