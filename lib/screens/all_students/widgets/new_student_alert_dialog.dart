import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:provider/provider.dart';

class NewStudentAlertDialog extends StatefulWidget {
  const NewStudentAlertDialog({
    super.key,
    this.student,
    this.deleteCallback,
  });

  final User? student;
  final Function(User)? deleteCallback;

  @override
  State<NewStudentAlertDialog> createState() => _NewStudentAlertDialogState();
}

class _NewStudentAlertDialogState extends State<NewStudentAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _firstName;
  String? _lastName;
  String? _email;

  void _finalize({bool hasCancelled = false}) {
    if (hasCancelled) {
      Navigator.pop(context);
      return;
    }

    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    var student = User(
      firstName: _firstName!,
      lastName: _lastName!,
      email: _email!,
      mustChangePassword: true,
      studentNotes: {},
      termsAndServicesAccepted: false,
      id: widget.student?.id,
      creationDate: DateTime.now(),
    );

    Navigator.pop(context, student);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        Provider.of<Database>(context, listen: false).currentUser;

    return AlertDialog(
      title: const Text('Informations de l\'élève à ajouter'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prénom'),
                initialValue: widget.student?.firstName,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ajouter un prénom' : null,
                onSaved: (value) => _firstName = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom'),
                initialValue: widget.student?.lastName,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ajouter un nom' : null,
                onSaved: (value) => _lastName = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Courriel'),
                initialValue: widget.student?.email,
                keyboardType: TextInputType.emailAddress,
                enabled: widget.student?.email == null,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ajouter un courriel'
                    : RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(value)
                        ? null
                        : 'Courriel non valide',
                onSaved: (value) => _email = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Entreprise de stage'),
                initialValue:
                    currentUser?.studentNotes[widget.student!.id] ?? '',
                validator: (value) => value == null || value.isEmpty
                    ? 'Ajouter une note associées à l\'élève (exemple : son entreprise de stage)'
                    : null,
                onSaved: (value) => widget.student?.id != null
                    ? currentUser?.studentNotes[widget.student!.id] =
                        value ?? ''
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (widget.student != null && widget.deleteCallback != null)
          IconButton(
            onPressed: () {
              _finalize(hasCancelled: true);
              widget.deleteCallback!(widget.student!);
            },
            icon: const Icon(Icons.delete),
          ),
        OutlinedButton(
          child: Text('Annuler',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary)),
          onPressed: () => _finalize(hasCancelled: true),
        ),
        ElevatedButton(
          child: Text(widget.student == null ? 'Ajouter' : 'Enregistrer',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () => _finalize(),
        ),
      ],
    );
  }
}
