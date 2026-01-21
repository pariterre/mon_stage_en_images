import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/common/helpers/helpers.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/misc/focus_nodes.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_questions.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:mon_stage_en_images/default_questions.dart';
import 'package:mon_stage_en_images/screens/login/widgets/forgot_password_alert_dialog.dart';
import 'package:mon_stage_en_images/screens/login/widgets/main_title_background.dart';
import 'package:provider/provider.dart';

final _logger = Logger('LoginScreen');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login-screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _emailController = TextEditingController()
    ..addListener(() => setState(() {}));
  late final _passwordController = TextEditingController()
    ..addListener(() => setState(() {}));
  final _focusNodes = FocusNodes()
    ..add('email')
    ..add('password');

  late UserType _userType;

  EzloginStatus _status = EzloginStatus.none;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();

    _userType = SharedPreferencesController.instance.userType;

    // Try automatic connexion
    _processConnexion(automaticConnexion: true, isUserNew: false);
  }

  void _showSnackbar() {
    late final String message;
    if (_status == EzloginStatus.waitingForLogin) {
      message = '';
    } else if (_status == EzloginStatus.cancelled) {
      message = 'La connexion a été annulée';
    } else if (_status == EzloginStatus.success) {
      message = '';
    } else if (_status == EzloginStatus.wrongUsername) {
      message = 'Utilisateur non enregistré';
    } else if (_status == EzloginStatus.wrongPassword) {
      message = 'Mot de passe non reconnu';
    } else {
      message = 'Erreur de connexion inconnue';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool get _canConnect {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _userType != UserType.none;
  }

  Future<void> _processConnexion(
      {required bool automaticConnexion, required bool isUserNew}) async {
    setState(() => _status = EzloginStatus.waitingForLogin);
    final database = Provider.of<Database>(context, listen: false);

    if (automaticConnexion) {
      if (database.currentUser == null) {
        setState(() => _status = EzloginStatus.none);
        return;
      }
      _status = EzloginStatus.success;
    } else {
      if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
        setState(() => _status = EzloginStatus.cancelled);
        return;
      }
      _formKey.currentState!.save();

      _status = await database
          .login(
              username: _emailController.text,
              password: _passwordController.text,
              userType: _userType)
          .then(
        (value) {
          _logger.info("$value login is complete");
          return value;
        },
      );
      if (_status != EzloginStatus.success) {
        _showSnackbar();
        setState(() {});
        return;
      }
      if (!mounted) return;
    }

    if (isUserNew && _userType == UserType.teacher) {
      final questions = Provider.of<AllQuestions>(context, listen: false);
      for (final question in DefaultQuestion.questions) {
        questions.add(question);
      }
    }
    Future.delayed(Duration(seconds: automaticConnexion ? 2 : 0), () async {
      if (!mounted) return;
      await RouteManager.instance.gotoTermsAndServicesPage(context);
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    await showDialog<bool?>(
      context: context,
      builder: (context) =>
          ForgotPasswordAlertDialog(email: _emailController.text),
    ).then((response) {
      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response
                ? "Un courriel de réinitialisation a été envoyé à l'adresse fournie, si elle correspond à un compte utilisateur"
                : "Une erreur est survenue, le courriel de réinitialisation n'a pas pu être envoyé."),
            backgroundColor: response
                ? Theme.of(context).snackBarTheme.backgroundColor
                : Theme.of(context).colorScheme.error));
      }
    });
  }

  Future<void> _newUser() async {
    String firstName = '';
    String lastName = '';
    String email = _emailController.text;
    String password = _passwordController.text;
    String? errorEmail;
    final focusNodes = FocusNodes()
      ..add('firstName')
      ..add('lastName')
      ..add('email')
      ..add('password')
      ..add('passwordConfirmation');
    StateSetter? setStateForm;
    final formKey = GlobalKey<FormState>();

    final isSuccess = await showDialog<bool?>(
      context: context,
      builder: (context) {
        Future<void> confirm() async {
          if (formKey.currentState == null ||
              !formKey.currentState!.validate() && _userType != UserType.none) {
            return;
          }

          if (!mounted) return;
          final database = Provider.of<Database>(context, listen: false);
          _emailController.text = email;
          _passwordController.text = password;

          final hasRegistered = await database.registerAsNewUser(
              newUser: User(
                firstName: firstName,
                lastName: lastName,
                email: _emailController.text,
                studentNotes: {},
                termsAndServicesAccepted: false,
                creationDate: DateTime.now(),
              ),
              password: _passwordController.text);
          if (!hasRegistered) {
            errorEmail = 'Ce courriel est déjà utilisé.';
            if (setStateForm != null) setStateForm!(() {});

            return;
          }

          await _processConnexion(automaticConnexion: false, isUserNew: true);
          if (!context.mounted) return;
          Navigator.pop(context, true);
        }

        return AreYouSureDialog(
            title: 'Inscription',
            content: 'Compléter les informations pour créer un nouveau compte',
            canReadAloud: true,
            onConfirmed: confirm,
            onCancelled: () {
              Navigator.pop(context, false);
            },
            extraContent: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setState) {
                  setStateForm = setState;
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 12),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Prénom'),
                          focusNode: focusNodes['firstName'],
                          onChanged: (value) => firstName = value,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Inscrire un prénom'
                              : null,
                          onEditingComplete: () => focusNodes.next(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Nom de famille'),
                          focusNode: focusNodes['lastName'],
                          onChanged: (value) => lastName = value,
                          validator: (value) {
                            return value == null || value.isEmpty
                                ? 'Inscrire un nom de famille'
                                : null;
                          },
                          onEditingComplete: () => focusNodes.next(),
                        ),
                        SizedBox(height: 8),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Je suis un(e) :',
                                style: TextStyle(fontSize: 16))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RadioTile(
                              value: UserType.student,
                              groupValue: _userType,
                              label: 'Élève',
                              onChanged: (value) {
                                _changeTypeSelection(value);
                                if (setStateForm != null) setStateForm!(() {});
                              },
                              selectedColor: studentTheme().colorScheme.primary,
                            ),
                            _RadioTile(
                              value: UserType.teacher,
                              groupValue: _userType,
                              label: 'Enseignant(e)',
                              onChanged: (value) {
                                _changeTypeSelection(value);
                                if (setStateForm != null) setStateForm!(() {});
                              },
                              selectedColor: teacherTheme().colorScheme.primary,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              labelText: 'Courriel', errorText: errorEmail),
                          initialValue: email,
                          focusNode: focusNodes['email'],
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => email = value,
                          validator: (value) {
                            errorEmail = Helpers.emailValidator(value);
                            return errorEmail;
                          },
                          onEditingComplete: () => focusNodes.next(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Mot de passe'),
                          initialValue: password,
                          focusNode: focusNodes['password'],
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (value) => password = value,
                          validator: Helpers.passwordValidator,
                          onEditingComplete: () => focusNodes.next(),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Confirmer le mot de passe'),
                          focusNode: focusNodes['passwordConfirmation'],
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (value) =>
                              Helpers.passwordConfirmationValidator(
                                  password, value),
                          onFieldSubmitted: (_) async => await confirm(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ));
      },
    );

    if (isSuccess != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('L\'inscription a été annulée'),
          duration: Duration(seconds: 5),
        ));
      }
      return;
    }
  }

  void _changeTypeSelection(UserType type) {
    _userType = type;
    SharedPreferencesController.instance.userType = type;
    setState(() {});
  }

  Widget _buildPage() {
    switch (_status) {
      case EzloginStatus.success:
        return Column(
          children: [
            CircularProgressIndicator(
              color: teacherTheme().colorScheme.primary,
            ),
            const Text('Connexion en cours...', style: TextStyle(fontSize: 18)),
          ],
        );
      case EzloginStatus.newUser:
      case EzloginStatus.waitingForLogin:
      case EzloginStatus.alreadyCreated:
        return CircularProgressIndicator(
          color: teacherTheme().colorScheme.primary,
        );
      case EzloginStatus.none:
      case EzloginStatus.cancelled:
      case EzloginStatus.wrongUsername:
      case EzloginStatus.wrongPassword:
      case EzloginStatus.wrongInfoWhileCreating:
      case EzloginStatus.couldNotCreateUser:
      case EzloginStatus.needAuthentication:
      case EzloginStatus.userNotFound:
      case EzloginStatus.unrecognizedError:
        return SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Informations de connexion',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text('Je suis un(e) :', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RadioTile(
                              value: UserType.student,
                              groupValue: _userType,
                              label: 'Élève',
                              onChanged: _changeTypeSelection,
                              selectedColor: studentTheme().colorScheme.primary,
                            ),
                            _RadioTile(
                              value: UserType.teacher,
                              groupValue: _userType,
                              label: 'Enseignant(e)',
                              onChanged: _changeTypeSelection,
                              selectedColor: teacherTheme().colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Courriel'),
                          focusNode: _focusNodes['email'],
                          validator: (value) => value == null || value.isEmpty
                              ? 'Inscrire un courriel'
                              : null,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (_) => _focusNodes.next(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              suffixIcon: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: IconButton.outlined(
                                    onPressed: () {
                                      _hidePassword = !_hidePassword;
                                      setState(() {});
                                    },
                                    icon: Icon(_hidePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off)),
                              )),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Entrer le mot de passe'
                              : null,
                          controller: _passwordController,
                          focusNode: _focusNodes['password'],
                          obscureText: _hidePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.visiblePassword,
                          onFieldSubmitted: (_) => _canConnect
                              ? _processConnexion(
                                  automaticConnexion: false, isUserNew: false)
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () {
                                _formKey.currentState?.save();
                                _showForgotPasswordDialog();
                              },
                              child: Text(
                                'Mot de passe oublié',
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold),
                              )),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canConnect
                            ? () => _processConnexion(
                                automaticConnexion: false, isUserNew: false)
                            : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                studentTheme().colorScheme.primary),
                        child: const Text('Se connecter'),
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _newUser,
                        child: const Text('Nouvel(le) utilisateur(trice)'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainTitleBackground(
          child: Theme(data: studentTheme(), child: _buildPage())),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.groupValue,
    required this.selectedColor,
  });

  final T value;
  final String label;
  final void Function(T) onChanged;
  final T groupValue;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? selectedColor : Colors.transparent,
        ),
        width: 160,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
