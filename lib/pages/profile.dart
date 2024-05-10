import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 70,
            left: 25,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 255, 215, 59),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ibrokhim Sidikov',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '+998 99 919 29 39',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                    ),
                  ],
                )
              ],
            ),
          ),
          Positioned(
            //menu list
            top: 200,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('images/inventory.svg'),
                    const SizedBox(
                      width: 25.0,
                    ),
                    Text(
                      'My Order History',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40.0,
                ),
                Row(
                  children: [
                    SvgPicture.asset('images/payment.svg'),
                    const SizedBox(
                      width: 25.0,
                    ),
                    Text(
                      'My Payment Card',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40.0,
                ),
                Row(
                  children: [
                    SvgPicture.asset('images/settings.svg'),
                    SizedBox(
                      width: 25.0,
                    ),
                    Text(
                      'Settings',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40.0,
                ),
                Text(
                  'Feedback',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(
                  height: 40.0,
                ),
                Text(
                  'About',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(
                  height: 40.0,
                ),
                Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(
                  height: 150,
                ),
                SvgPicture.asset('images/lookSupport.svg'),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Version 1.0.0, build 10001')],
        ),
      ),
    );
  }
}
