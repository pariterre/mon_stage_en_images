import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';
import 'package:mon_stage_en_images/screens/login/widgets/main_title_background.dart';
import 'package:url_launcher/url_launcher.dart';

class GoToIrsstScreen extends StatelessWidget {
  const GoToIrsstScreen({super.key});

  static const routeName = '/go-to-irsst-screen';

  // TODO Confirm the link
  static final learnAboutSstUri = Uri(
    scheme: 'https',
    host: 'monstageenimages.adoprevit.org',
    path: 'resources/ApprendreSST.pdf',
  );

  @override
  Widget build(context) {
    return Scaffold(
      body: Center(
        child: MainTitleBackground(
            child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
                'Vous trouverez des informations utiles et ludiques '
                'concernant la Santé et sécurité au travail (SST) en '
                'suivant ce lien. Vous pouvez accéder à ce lien à '
                'partir de l\'application en tout temps en cliquant '
                'sur le bouton "IRSST" dans le menu principal. ',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async => await launchUrl(learnAboutSstUri),
                  style: studentTheme().elevatedButtonTheme.style,
                  child: const Text('Accéder au PDF'),
                ),
                ElevatedButton(
                    onPressed: () {
                      SharedPreferencesController
                          .instance.hasAlreadySeenTheIrrstPage = true;
                      RouteManager.instance.gotoStudentsPage(context);
                    },
                    style: studentTheme().elevatedButtonTheme.style,
                    child: const Text('Continuer')),
              ],
            )
          ],
        )),
      ),
    );
  }
}
