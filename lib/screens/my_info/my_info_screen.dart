import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/helpers.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/misc/focus_nodes.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/widgets/main_drawer.dart';
import 'package:mon_stage_en_images/common/widgets/user_info_dialog.dart';
import 'package:provider/provider.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({
    super.key,
  });

  static const routeName = '/my-info-screen';

  @override
  State<MyInfoScreen> createState() => MyInfoScreenState();
}

//StudentsScreenState is purposefully made public so onboarding can access its inner methods (like openDrawer)
class MyInfoScreenState extends State<MyInfoScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    final database = Provider.of<Database>(context, listen: false);
    switch (database.userType) {
      case UserType.none:
      case UserType.student:
        break;
      case UserType.teacher:
        // If this is the first time we come to this screen, we show the onboarding
        SharedPreferencesController.instance.hasSeenOnboarding ??= false;
    }
  }

  PreferredSizeWidget _setAppBar() {
    return ResponsiveService.appBarOf(
      context,
      title: const Text('Mes informations'),
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    final user = database.currentUser;
    if (user == null) {
      return SizedBox.shrink();
    }

    final fontSize = 20.0;

    return ResponsiveService.scaffoldOf(
      context,
      key: scaffoldKey,
      appBar: _setAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Center(
                child: Text('Mes informations',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Nom, prénom : ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: fontSize)),
                  Text('${user.firstName} ${user.lastName}',
                      style: TextStyle(fontSize: fontSize)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Courriel : ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: fontSize)),
                  Text(user.email, style: TextStyle(fontSize: fontSize)),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => UserInfoDialog(
                                    title: const Text('Mes informations'),
                                    editInformation: true,
                                    user: user,
                                  ));
                        },
                        child: Text('Modifier mes informations')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                        onPressed: () async {
                          final isSuccess = await showDialog<bool>(
                              context: context,
                              builder: (context) =>
                                  const _ChangePasswordAlertDialog());
                          if (isSuccess != true) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Changement de mot de passe annulé')));
                            }
                          }
                        },
                        // TODO Sizedbox
                        child: Text('Changer mon mot de passe')),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      smallDrawer: MainDrawer.small(),
      mediumDrawer: MainDrawer.medium(),
      largeDrawer: MainDrawer.large(),
    );
  }
}

class _ChangePasswordAlertDialog extends StatefulWidget {
  const _ChangePasswordAlertDialog();

  @override
  State<_ChangePasswordAlertDialog> createState() =>
      _ChangePasswordAlertDialogState();
}

class _ChangePasswordAlertDialogState
    extends State<_ChangePasswordAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  String? _oldPasswordError;
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _focusNodes = FocusNodes()
    ..add('oldPassword')
    ..add('newPassword')
    ..add('confirmPassword');

  Future<void> _finalize() async {
    _formKey.currentState!.save();
    setState(() {
      _oldPasswordError = _oldPassword.text.isEmpty
          ? 'Veuillez entrer le mot de passe actuel'
          : null;
    });
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final database = Provider.of<Database>(context, listen: false);
    final status = await database.updatePassword(
        user: database.currentUser!,
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text);

    if (status == EzloginStatus.success) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mot de passe changé avec succès')));
      return;
    }

    _oldPasswordError = switch (status) {
      EzloginStatus.wrongPassword => 'Le mot de passe actuel est incorrect',
      _ => 'Une erreur est survenue lors du changement de mot de passe',
    };
    setState(() {});
  }

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Svp, changer votre mot de passe'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                  controller: _oldPassword,
                  focusNode: _focusNodes['oldPassword'],
                  decoration: InputDecoration(
                      labelText: 'Entrer le mot de passe actuel',
                      errorText: _oldPasswordError),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.visiblePassword,
                  onFieldSubmitted: (_) => _focusNodes.next()),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassword,
                focusNode: _focusNodes['newPassword'],
                decoration: const InputDecoration(
                    labelText: 'Entrer le nouveau mot de passe'),
                validator: Helpers.passwordValidator,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.visiblePassword,
                onFieldSubmitted: (_) => _focusNodes.next(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassword,
                focusNode: _focusNodes['confirmPassword'],
                decoration: const InputDecoration(
                    labelText: 'Copier le nouveau mot de passe'),
                validator: (value) => Helpers.passwordConfirmationValidator(
                    _newPassword.text, value),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.visiblePassword,
                onFieldSubmitted: (_) => _finalize(),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary)),
        ),
        ElevatedButton(
          child: Text('Enregistrer',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () => _finalize(),
        ),
      ],
    );
  }
}
