import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final String phoneNumber = '71-207-207-0';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar(),
      body: Column(
        children: [
          const SizedBox(
            height: 70.0,
          ),
          Center(
            child: Image.asset(
              'images/look_signin.png',
              width: 300,
              height: 300,
            ),
          ),
          Center(
            child: Text(
              AppLocalizations.of(context).signInToYourProfile,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              AppLocalizations.of(context).underTitle,
              style: TextStyle(fontWeight: FontWeight.w200),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Authorization()));
              },
              child: Container(
                padding:
                    EdgeInsets.only(left: 40, right: 40, top: 15, bottom: 15),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xffFEC700)),
                child: Text(
                  AppLocalizations.of(context).phoneNumberButton,
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
          Center(
            child: Text(
              AppLocalizations.of(context).privacyPolicy,
              style: TextStyle(fontWeight: FontWeight.w100, fontSize: 13),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Center(
            child: Text(
              'Version 1.0.0, build 10001',
              style: TextStyle(
                  fontWeight: FontWeight.w100,
                  fontSize: 13,
                  color: Colors.black26),
            ),
          )
        ],
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context).signIn,
        style: TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      elevation: 0.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pushReplacementNamed(context, '/homeNew');
        },
        child: Container(
          margin: EdgeInsets.all(10),
          child: SvgPicture.asset(
            'images/keyboard_arrow_left.svg',
            height: 30,
            width: 30,
          ),
          decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Call-Center"),
                  content: Text(
                      "Bizning call-markazimiz bilan \naloqaga chiqing \n$phoneNumber"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Call",
                        style:
                            TextStyle(color: Color.fromARGB(255, 255, 215, 72)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          child: Container(
            margin: EdgeInsets.all(10),
            width: 37,
            child: SvgPicture.asset(
              'images/perm_phone_msg.svg',
              height: 30,
              width: 30,
            ),
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
