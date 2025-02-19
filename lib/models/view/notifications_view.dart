import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F2F7),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).notifications,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/homeNew');
          },
          child: SizedBox(
            height: 25,
            width: 25,
            child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('images/noNotifications.svg'),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noNotifications,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
