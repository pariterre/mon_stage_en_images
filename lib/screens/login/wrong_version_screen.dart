import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/screens/login/widgets/main_title_background.dart';

class WrongVersionScreen extends StatelessWidget {
  const WrongVersionScreen({super.key});

  static const routeName = '/wrong-version-screen';

  @override
  Widget build(context) {
    return Scaffold(
      body: Center(
        child: MainTitleBackground(
            child: const Text(
                'La version de l\'application est obsolète. '
                'Veuillez télécharger la dernière mise à jour '
                'sur App Store ou Google Play Store.',
                style: TextStyle(fontSize: 18))),
      ),
    );
  }
}
