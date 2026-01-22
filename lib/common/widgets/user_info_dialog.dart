import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/misc/focus_nodes.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:provider/provider.dart';

class UserInfoDialog extends StatefulWidget {
  const UserInfoDialog({
    super.key,
    required this.title,
    this.editInformation = false,
    this.showEditableNotes = false,
    required this.user,
    this.onRemoveFromList,
  });

  final Widget title;
  final User user;
  final bool editInformation;
  final bool showEditableNotes;
  final Future<void> Function(String password)? onRemoveFromList;

  @override
  State<UserInfoDialog> createState() => _UserInfoDialogState();
}

class _UserInfoDialogState extends State<UserInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController =
      TextEditingController(text: widget.user.firstName);
  late final _lastNameController =
      TextEditingController(text: widget.user.lastName);
  late final _emailController = TextEditingController(text: widget.user.email);

  late final _noteController = TextEditingController(
      text: Provider.of<Database>(context, listen: false)
          .currentUser
          ?.studentNotes[widget.user.id]);

  final _focusNodes = FocusNodes();

  @override
  void initState() {
    super.initState();

    if (widget.editInformation) {
      _focusNodes.add('firstName');
      _focusNodes.add('lastName');
      _focusNodes.add('email');
    }
    if (widget.showEditableNotes) {
      _focusNodes.add('note');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _noteController.dispose();

    _focusNodes.dispose();

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

  void _save() {
    final database = Provider.of<Database>(context, listen: false);
    final user = database.currentUser!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newUser = user.copyWith(
      firstName:
          widget.editInformation ? _firstNameController.text : user.firstName,
      lastName:
          widget.editInformation ? _lastNameController.text : user.lastName,
      email: widget.editInformation ? _emailController.text : user.email,
      studentNotes: {
        ...user.studentNotes,
        widget.user.id: _noteController.text
      },
    );

    database.modifyUser(user: user, newInfo: newUser);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              widget.editInformation
                  ? Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 175,
                              child: TextFormField(
                                controller: _firstNameController,
                                focusNode: _focusNodes['firstName'],
                                decoration:
                                    const InputDecoration(labelText: 'Prénom'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Le prénom ne peut pas être vide';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) =>
                                    _focusNodes['lastName']!.requestFocus(),
                              ),
                            ),
                            SizedBox(width: 12),
                            SizedBox(
                              width: 175,
                              child: TextFormField(
                                controller: _lastNameController,
                                focusNode: _focusNodes['lastName'],
                                decoration:
                                    const InputDecoration(labelText: 'Nom'),
                                onFieldSubmitted: (_) => _save(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Le nom ne peut pas être vide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text('Nom, prénom : ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            '${widget.user.firstName} ${widget.user.lastName}'),
                      ],
                    ),
              const SizedBox(height: 8),
              widget.editInformation
                  ? Column(
                      children: [
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _focusNodes['email'],
                          enabled: false,
                          decoration:
                              const InputDecoration(labelText: 'Courriel'),
                          onFieldSubmitted: (_) => _save(),
                        )
                      ],
                    )
                  : Row(
                      children: [
                        Text('Courriel : ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.user.email),
                      ],
                    ),
              if (widget.showEditableNotes)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      focusNode: _focusNodes['note'],
                      decoration: const InputDecoration(
                          labelText: 'Note personnelle de l\'élève'),
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (widget.onRemoveFromList != null)
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

              await widget.onRemoveFromList!(_password);
            },
            icon: const Icon(Icons.delete),
          ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary)),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text('Enregistrer',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }
}
