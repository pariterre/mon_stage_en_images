import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/text_reader.dart';

class AreYouSureDialog extends StatelessWidget {
  const AreYouSureDialog({
    super.key,
    required this.title,
    required this.content,
    this.canReadAloud = false,
  });

  final String title;
  final String content;
  final bool canReadAloud;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Row(
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
          Text(content),
        ],
      ),
      actions: [
        OutlinedButton(
          child: const Text('Annuler'),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          child: const Text('Continuer'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
