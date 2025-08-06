import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class UpdateRequiredDialog extends StatelessWidget {
  final String currentVersion;
  final String requiredVersion;

  const UpdateRequiredDialog({
    Key? key,
    required this.currentVersion,
    required this.requiredVersion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to get localizations, but provide fallback strings if not available
    AppLocalizations? localizations;
    try {
      localizations = AppLocalizations.of(context);
    } catch (e) {
      print('Error getting localizations: $e');
      // Localizations not available, will use fallback strings
    }

    // Fallback strings if localizations are not available
    final String updateRequiredTitle = localizations?.updateRequired ?? 'Update Required';
    final String updateRequiredDesc = localizations?.updateRequiredDescription ?? 
        'A new version of the app is available and required to continue using the app. Please update to the latest version.';
    final String currentVersionText = localizations?.currentVersion ?? 'Current Version';
    final String requiredVersionText = localizations?.requiredVersion ?? 'Required Version';
    final String updateButtonText = localizations?.updateNow ?? 'Update Now';
    
    // Use platform-specific dialog style
    if (Platform.isIOS) {
      return _buildIOSStyleDialog(
        context,
        updateRequiredTitle,
        updateRequiredDesc,
        currentVersionText,
        requiredVersionText,
        updateButtonText,
      );
    } else {
      return _buildMaterialDialog(
        context,
        updateRequiredTitle,
        updateRequiredDesc,
        currentVersionText,
        requiredVersionText,
        updateButtonText,
      );
    }
  }
  
  Widget _buildIOSStyleDialog(
    BuildContext context,
    String title,
    String description,
    String currentVersionText,
    String requiredVersionText,
    String updateButtonText,
  ) {
    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoAlertDialog(
        title: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                CupertinoIcons.arrow_up_circle,
                color: CupertinoColors.activeBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            children: [
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentVersionText: ',
                          style: const TextStyle(color: CupertinoColors.systemGrey),
                        ),
                        Text(
                          currentVersion,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$requiredVersionText: ',
                          style: const TextStyle(color: CupertinoColors.systemGrey),
                        ),
                        Text(
                          requiredVersion,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => _launchAppStore(),
            child: Text(
              updateButtonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialDialog(
    BuildContext context,
    String title,
    String description,
    String currentVersionText,
    String requiredVersionText,
    String updateButtonText,
  ) {
    return WillPopScope(
      // Prevent dialog from being dismissed by back button
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(
              Icons.system_update,
              color: Theme.of(context).primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$currentVersionText: ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        currentVersion,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$requiredVersionText: ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        requiredVersion,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _launchAppStore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(updateButtonText),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        buttonPadding: const EdgeInsets.only(bottom: 16),
      ),
    );
  }
  Future<void> _launchAppStore() async {
    // URLs for app stores - use the correct package name for your app
    const String appStoreUrl = 'https://apps.apple.com/app/loook/id1234567890';
    const String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.loook.v1';

    try {
      // Determine the platform and launch the appropriate URL
      final url = Platform.isIOS ? appStoreUrl : playStoreUrl;
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching app store: $e');
    }
  }
}

// Navigator key is imported from main.dart
