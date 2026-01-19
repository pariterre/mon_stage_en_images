import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:provider/provider.dart';

class StudentInfoDialog extends StatefulWidget {
  const StudentInfoDialog({
    super.key,
    required this.student,
    required this.onRemoveFromList,
  });

  final User student;
  final Future<void> Function(String password) onRemoveFromList;

  @override
  State<StudentInfoDialog> createState() => _StudentInfoDialogState();
}

class _StudentInfoDialogState extends State<StudentInfoDialog> {
  late final _noteController = TextEditingController(
      text: Provider.of<Database>(context, listen: false)
          .currentUser
          ?.studentNotes[widget.student.id]);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Informations de l\'élève'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text('Nom, prénom : ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${widget.student.firstName} ${widget.student.lastName}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Courriel : ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.student.email),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                    labelText: 'Note associée à l\'élève')),
          ],
        ),
      ),
      actions: <Widget>[
        IconButton(
          onPressed: () async {
            final passwordController = TextEditingController();
            final sure = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AreYouSureDialog(
                    title: 'Retirer de la liste',
                    content:
                        'Êtes-vous sûr de vouloir retirer cet élève de la liste d\'élèves inscrits à votre code d\'inscription ?\n'
                        'Cette action est irréversible.\n\n'
                        'Veuillez entrer votre mot de passe pour confirmer :',
                    extraContent: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: TextField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'Mot de passe'),
                        obscureText: true,
                        autofocus: true,
                      ),
                    ),
                  );
                });

            final password = passwordController.text;
            passwordController.dispose();
            if (sure != true || password.isEmpty || !context.mounted) return;

            if (context.mounted) Navigator.pop(context);
            await widget.onRemoveFromList(password);
          },
          icon: const Icon(Icons.delete),
        ),
        OutlinedButton(
          child: Text('Annuler',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Enregistrer',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () => Navigator.pop(context, _noteController.text),
        ),
      ],
    );
  }
}
