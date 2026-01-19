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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  final _passwordFormKey = GlobalKey<FormState>();
  StateSetter? _passwordDialogSetState;
  String _password = '';
  String? _passwordError;
  Future<void> _validatePasswordDialogForm() async {
    if (_password.isEmpty) {
      if (_passwordDialogSetState != null) {
        _passwordDialogSetState!(() {
          _passwordError = 'Veuillez entrer votre mot de passe';
        });
      }
      return;
    }

    // Check if the password is correct
    final database = Provider.of<Database>(context, listen: false);
    final loginStatus = await database.login(
        username: database.currentUser!.email,
        password: _password,
        skipPostLogin: true);
    if (loginStatus != EzloginStatus.success) {
      if (_passwordDialogSetState != null) {
        _passwordDialogSetState!(() {
          _passwordError = 'Le mot de passe entré est incorrect';
        });
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

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
            final isSuccess = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      _passwordDialogSetState = setState;
                      return AreYouSureDialog(
                        title: 'Retirer de la liste',
                        content:
                            'Êtes-vous sûr de vouloir retirer cet élève de la liste d\'élèves inscrits à votre code d\'inscription ?\n'
                            'Cette action est irréversible.\n\n'
                            'Veuillez entrer votre mot de passe pour confirmer :',
                        extraContent: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Form(
                            key: _passwordFormKey,
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                errorText: _passwordError,
                              ),
                              obscureText: true,
                              autofocus: true,
                              onChanged: (value) {
                                _password = value;
                                _passwordDialogSetState!(() {
                                  _passwordError = null;
                                });
                              },
                              onFieldSubmitted: (_) =>
                                  _validatePasswordDialogForm(),
                              validator: (value) => _passwordError,
                            ),
                          ),
                        ),
                        onCancelled: () => Navigator.pop(context, false),
                        onConfirmed: _validatePasswordDialogForm,
                      );
                    },
                  );
                });
            _passwordDialogSetState = null;
            if (context.mounted) Navigator.pop(context);
            if (isSuccess != true || !context.mounted) return;

            await widget.onRemoveFromList(_password);
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
          onPressed: () => _validatePasswordDialogForm(),
        ),
      ],
    );
  }
}
