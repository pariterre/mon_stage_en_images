import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/providers/database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PushNotificationsHelpers {
  static Future<void> setupPushNotifications(BuildContext context) async {
    if (kIsWeb) return;

    final fcm = FirebaseMessaging.instance;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.notDetermined:
        await fcm.requestPermission();
        break;
      case AuthorizationStatus.denied:
        {
          if (true) {
            //SharedPreferencesController.instance.showPermissionRefused) {
            SharedPreferencesController.instance.showPermissionRefused = false;
            if (!context.mounted) return;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Notifications désactivées'),
                content: const Text(
                    'Les notifications push sont désactivées sur votre appareil.\n'
                    'Pour les activer, veuillez aller dans les paramètres de votre appareil.'),
                actions: [
                  TextButton(
                      onPressed: () async => await openAppSettings(),
                      child: Text('Paramètres')),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuer'),
                  ),
                ],
              ),
            );
          }
          break;
        }
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        break;
    }

    final token = await fcm.getToken();
    if (!context.mounted || token == null) return;
    print(token);

    // TODO update user
    final database = Provider.of<Database>(context, listen: false);
    final user = database.currentUser;
    if (user == null) throw Exception('No user is currently logged in.');

    final userTokens = [...user.pushNotificationsTokens];
    if (!userTokens.contains(token)) {
      userTokens.add(token);
      await database.modifyUser(
          user: user,
          newInfo: user.copyWith(pushNotificationsTokens: userTokens));
    }
  }
}
