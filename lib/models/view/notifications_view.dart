import 'package:apploook/l10n/app_localizations.dart';
import  'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).notifications),
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
        child: Text(AppLocalizations.of(context).notificationsPlaceholder),
      ),
    );
  }
}