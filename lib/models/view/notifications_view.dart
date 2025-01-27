import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/providers/locale_provider.dart';
import  'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

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
        title: Text('Notifications'),
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
      body: Column(
        children: [
          Center(
            child: Text(AppLocalizations.of(context).notification),
          ),
          ListTile(
            title: Text('Language / Til'),
            trailing: DropdownButton<String>(
              value: context.watch<LocaleProvider>().locale.languageCode,
              items: [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'uz', child: Text('O\'zbek')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  context.read<LocaleProvider>().setLocale(Locale(value));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}