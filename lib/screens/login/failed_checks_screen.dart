import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/widgets/text_clipboard_copy.dart';
import 'package:mon_stage_en_images/screens/login/widgets/main_title_background.dart';

class FailedChecksScreen extends StatelessWidget {
  const FailedChecksScreen({super.key, this.exception});

  static const routeName = '/failed-check-screen';

  final Exception? exception;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Scaffold(
      body: MainTitleBackground(
        child: Column(
          children: [
            Icon(
              Icons.wifi_off,
              size: 60,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
                'Stage en images n\'a pas pu effectuer les vérifications'
                ' nécessaires à son lancement.',
                style: textStyle),
            SizedBox(
              height: 20,
            ),
            Text(
              'Vérifiez votre accès à Internet, puis fermez et relancez l\'application',
              style: textStyle,
            ),
            if (exception != null && kDebugMode) ...[
              SizedBox(
                height: 40,
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description de l\'erreur rencontrée :',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Card.filled(
                          color: Theme.of(context).colorScheme.tertiary,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                                TextClipboardCopy(text: exception.toString()),
                          )),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
