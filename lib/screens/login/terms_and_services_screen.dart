import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/text_reader.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';
import 'package:mon_stage_en_images/screens/login/widgets/main_title_background.dart';
import 'package:provider/provider.dart';

class TermsAndServicesScreen extends StatelessWidget {
  const TermsAndServicesScreen({super.key});

  static const routeName = '/terms-and-services-screen';

  Future<void> _acceptTermsAndServices(BuildContext context) async {
    final database = Provider.of<Database>(context, listen: false);
    final user = database.currentUser!;
    await database.modifyUser(
        user: user, newInfo: user.copyWith(termsAndServicesAccepted: true));

    if (!context.mounted) return;
    RouteManager.instance.gotoIrsstPage(context);
  }

  @override
  Widget build(context) {
    const termsAndServicesText =
        'En cliquant sur « Accepter », vous acceptez d\'utiliser l\'application '
        '« Mon stage en image » et la messagerie qui y est intégrée de façon '
        'responsable et respectueuse. Il est interdit d\'y tenir des propos '
        'offensants ou de partager des images inappropriées avec la fonction '
        'de partage d\'images.\n\n'
        'Ne pas respecter ces conditions pourrait entraîner des '
        'sanctions allant jusqu\'à la suspension de votre compte.';

    return Scaffold(
      body: Center(
        child: MainTitleBackground(
            child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Conditions d\'utilisation',
                      style: TextStyle(fontSize: 24)),
                  IconButton(
                      onPressed: () {
                        final textReader = TextReader();
                        textReader.readText(
                          'Conditions d\'utilisation.\n$termsAndServicesText\n'
                          'Cliquez sur « Accepter les conditions » si vous acceptez.',
                          hasFinishedCallback: () => textReader.stopReading(),
                        );
                      },
                      icon: const Icon(Icons.volume_up))
                ],
              ),
              const Text(termsAndServicesText),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () => _acceptTermsAndServices(context),
                      style: studentTheme().elevatedButtonTheme.style,
                      child: const Text('Accepter les conditions')),
                ],
              )
            ],
          ),
        )),
      ),
    );
  }
}
