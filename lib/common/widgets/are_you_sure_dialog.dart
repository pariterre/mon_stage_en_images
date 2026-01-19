import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/text_reader.dart';

class AreYouSureDialog extends StatelessWidget {
  const AreYouSureDialog({
    super.key,
    required this.title,
    required this.content,
    this.extraContent,
    this.canReadAloud = false,
    required this.onConfirmed,
    required this.onCancelled,
  });

  final String title;
  final String content;
  final bool canReadAloud;
  final Widget? extraContent;
  final Function() onConfirmed;
  final Function() onCancelled;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (canReadAloud)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                      onPressed: () {
                        final textReader = TextReader();
                        textReader.readText(
                          content,
                          hasFinishedCallback: () => textReader.stopReading(),
                        );
                      },
                      icon: const Icon(Icons.volume_up)),
                ),
              Flexible(child: Text(content)),
            ],
          ),
          if (extraContent != null) extraContent!,
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: onCancelled,
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: onConfirmed,
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}
