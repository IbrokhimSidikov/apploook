import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentScreen extends StatelessWidget {
  final VoidCallback onAccept;

  const ConsentScreen({Key? key, required this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Privacy Policy'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Introduction\n\n'
                    'Our privacy policy will help you understand what information we collect at Loook, how Loook uses it, and what choices you have. Loook built the Loook app as a free app. This SERVICE is provided by Loook at no cost and is intended for use as is. If you choose to use our Service, then you agree to the collection and use of information in relation with this policy. The Personal Information that we collect are used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy. The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible in our website, unless otherwise defined in this Privacy Policy.\n\n'
                    // Truncated for brevity...
                    'Contact Information:\n'
                    'Email: loook.uz.tech@gmail.com',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(140, 40),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('accepted_privacy_policy', true);
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFECC00),
                      fixedSize: Size(140, 40),
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
