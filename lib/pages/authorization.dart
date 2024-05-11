import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

class Authorization extends StatefulWidget {
  const Authorization({super.key});

  @override
  State<Authorization> createState() => _AuthorizationState();
}

class _AuthorizationState extends State<Authorization> {
  // TextEditingController _phoneNumberController =
  // TextEditingController(text: '+998 ');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Authorization',
          style: TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 75,
          ),
          Center(
            child: Text(
              'Please enter your number\nto log in the application',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 50.0,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 70, right: 70),
              child: PhoneFormField(
                initialValue: PhoneNumber.parse('+998'),
                validator: PhoneValidator.compose([
                  PhoneValidator.required(context),
                  PhoneValidator.validMobile(context),
                ]),
                enabled: true,
                isCountrySelectionEnabled: false,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Disable country selection
                countryButtonStyle: const CountryButtonStyle(
                  showDialCode: true, // Display +998
                  showIsoCode: false, // Hide ISO code (optional)
                  showFlag: true, // Display Uzbekistan flag (optional)
                  flagSize: 16,
                ),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeNew()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 215, 56),
              ),
              child: const Padding(
                padding: EdgeInsets.only(
                    left: 40.0, right: 40.0, top: 10.0, bottom: 10.0),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 20,
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
