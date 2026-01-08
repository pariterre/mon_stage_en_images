import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';
import 'package:mon_stage_en_images/screens/login/widgets/main_title_background.dart';
import 'package:url_launcher/url_launcher.dart';

class GoToIrsstScreen extends StatelessWidget {
  const GoToIrsstScreen({super.key});

  static const routeName = '/go-to-irsst-screen';

  static final url = Uri(
    scheme: 'https',
    host: 'www.irsst.qc.ca',
    path:
        'publications-et-outils/publication/i/101076/n/sst-supervision-de-stages-',
  );

  Future<void> _goVisitWebSite(BuildContext context) async {
    await launchUrl(url);
    if (!context.mounted) return;
    await RouteManager.instance.gotoStudentsPage(context);
  }

  @override
  Widget build(context) {
    SharedPreferencesManager.instance.hasAlreadySeenTheIrrstPage = true;

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
                  onPressed: () => _goVisitWebSite(context),
                  style: studentTheme().elevatedButtonTheme.style,
                  child: const Text('Visiter le site web'),
                ),
                ElevatedButton(
                    onPressed: () =>
                        RouteManager.instance.gotoStudentsPage(context),
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
