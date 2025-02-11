import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentScreen extends StatelessWidget {
  final Function onAccept;

  ConsentScreen({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Your privacy policy goes here...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('accepted_privacy_policy', true);
                    onAccept();
                  },
                  child: Text('Accept'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Handle decline logic here, e.g., close the app
                    Navigator.of(context).pop();
                  },
                  child: Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
