import 'package:apploook/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Column(
        children: [
          SizedBox(
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
              'Sign in to your profile',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'To order, do authorization first',
              style: TextStyle(fontWeight: FontWeight.w200),
            ),
          ),
          SizedBox(
            height: 25,
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SignUp()));
              },
              child: Container(
                padding:
                    EdgeInsets.only(left: 40, right: 40, top: 15, bottom: 15),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xffFEC700)),
                child: Text(
                  'Enter your phone number',
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
              'Privacy policy',
              style: TextStyle(fontWeight: FontWeight.w100, fontSize: 13),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Center(
            child: Text(
              'Version 1.0.0, build 10001',
              style: TextStyle(fontWeight: FontWeight.w100, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      elevation: 0.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {},
        child: Container(
          margin: EdgeInsets.all(10),
          child: SvgPicture.asset(
            'images/keyboard_arrow_left.svg',
            height: 30,
            width: 30,
          ),
          decoration: BoxDecoration(
              color: Color(0xffF7F8F8),
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.all(10),
            width: 37,
            child: SvgPicture.asset(
              'images/perm_phone_msg.svg',
              height: 30,
              width: 30,
            ),
            decoration: BoxDecoration(
                color: Color(0xffF7F8F8),
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
