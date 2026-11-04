import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/l10n/app_localizations_delegate.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/services/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// Blocks the whole app with an undismissable dialog while the
/// `maintenance_enabled` Remote Config flag is on.
///
/// It sits above every MaterialApp instead of using showDialog, so route
/// changes, pushed pages and pending pops cannot remove it, and the app
/// underneath keeps its state until maintenance ends.
///
/// Must stay above the MaterialApps: observers run in registration order, so
/// this one gets system back before their navigators can pop a page.
class MaintenanceGate extends StatefulWidget {
  final Widget child;

  const MaintenanceGate({Key? key, required this.child}) : super(key: key);

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate>
    with WidgetsBindingObserver {
  final RemoteConfigService _remoteConfig = RemoteConfigService();
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remoteConfig.maintenanceChanges.addListener(_onMaintenanceChanged);
  }

  @override
  void dispose() {
    _remoteConfig.maintenanceChanges.removeListener(_onMaintenanceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onMaintenanceChanged() {
    final enabled = _remoteConfig.maintenanceEnabled;
    if (enabled && !_enabled) {
      // Close the keyboard so nothing can be typed into the page underneath.
      FocusManager.instance.primaryFocus?.unfocus();
    }
    // Always rebuild: the message can change while the dialog is showing.
    setState(() {
      _enabled = enabled;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _remoteConfig.refreshMaintenanceStatus();
    }
  }

  // System back leaves the app rather than popping the page underneath.
  @override
  Future<bool> didPopRoute() async {
    if (!_enabled) return false;
    await SystemNavigator.pop();
    return true;
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => _enabled;

  @override
  void handleCommitBackGesture() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: _enabled,
          child: widget.child,
        ),
        if (_enabled)
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'LOOOK MOBILE',
                theme: ThemeData(
                  fontFamily: 'Poppins',
                  useMaterial3: true,
                ),
                locale: localeProvider.locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('uz'),
                  Locale('ru'),
                ],
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: _MaintenanceDialog(
                  remoteMessage: _remoteConfig
                      .maintenanceMessage(localeProvider.locale.languageCode),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _MaintenanceDialog extends StatelessWidget {
  final String remoteMessage;

  const _MaintenanceDialog({required this.remoteMessage});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        AlertDialog(
          scrollable: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Icon(
                Icons.build_circle_outlined,
                color: Color(0xFFFEC700),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.maintenanceTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            remoteMessage.isNotEmpty
                ? remoteMessage
                : localizations.maintenanceDescription,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
