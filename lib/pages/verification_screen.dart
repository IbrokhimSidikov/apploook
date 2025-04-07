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
          // Clear verification code after successful login
          _authService.clearVerificationCode();
          Navigator.pushNamed(context, '/homeNew');
        } else {
          _codeController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Verification failed'),
            ),
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
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).verification,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 215, 56)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 40,
                        color: Color.fromARGB(255, 255, 215, 56),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context).verificationTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the 4-digit code sent to\n${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    PinCodeTextField(
                      appContext: context,
                      length: 4,
                      controller: _codeController,
                      onChanged: (value) {},
                      onCompleted: (value) => _verifyCode(),
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.scale,
                      animationDuration: const Duration(milliseconds: 200),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 56,
                        fieldWidth: 56,
                        activeColor: const Color.fromARGB(255, 255, 215, 56),
                        selectedColor: const Color.fromARGB(255, 255, 215, 56),
                        inactiveColor: Colors.grey.withOpacity(0.3),
                        activeFillColor: const Color.fromARGB(255, 255, 215, 56)
                            .withOpacity(0.1),
                        selectedFillColor:
                            const Color.fromARGB(255, 255, 215, 56)
                                .withOpacity(0.1),
                        inactiveFillColor: Colors.grey.withOpacity(0.05),
                      ),
                      enableActiveFill: true,
                      cursorColor: const Color.fromARGB(255, 255, 215, 56),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 215, 56),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          // Add resend code functionality here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code resent'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          'Resend Code',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
