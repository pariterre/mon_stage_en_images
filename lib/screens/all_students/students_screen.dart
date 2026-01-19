import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/helpers/teaching_token_helpers.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:mon_stage_en_images/common/widgets/main_drawer.dart';
import 'package:mon_stage_en_images/default_onboarding_steps.dart';
import 'package:mon_stage_en_images/onboarding/onboarding.dart';
import 'package:provider/provider.dart';

import 'widgets/student_info_dialog.dart';
import 'widgets/student_list_tile.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({
    super.key,
  });

  static const routeName = '/students-screen';

  @override
  State<StudentsScreen> createState() => StudentsScreenState();
}

void _showSnackbar(Widget content, ScaffoldMessengerState scaffold) {
  scaffold.showSnackBar(
    SnackBar(
        content: content,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: scaffold.hideCurrentSnackBar,
        )),
  );
}

//StudentsScreenState is purposefully made public so onboarding can access its inner methods (like openDrawer)
class StudentsScreenState extends State<StudentsScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    switch (Provider.of<Database>(context, listen: false).userType) {
      case UserType.none:
      case UserType.student:
        break;
      case UserType.teacher:
        // If this is the first time we come to this screen, we show the onboarding
        SharedPreferencesController.instance.hasSeenOnboarding ??= false;
    }
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
  bool? get isDrawerOpen => scaffoldKey.currentState?.isDrawerOpen;

  Future<void> _showCurrentToken() async {
    final teacherId =
        Provider.of<Database>(context, listen: false).currentUser!.id;

    final token =
        await TeachingTokenHelpers.createdActiveToken(userId: teacherId);
    if (!mounted) return;
    if (token == null) {
      _showSnackbar(
          const Text('Aucun code actif n\'a été trouvé pour ce compte'),
          ScaffoldMessenger.of(context));
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Code d\'inscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SelectableText(
                  token,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                  'Les élèves peuvent utiliser ce code pour s\'inscrire à votre tableau.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _generateNewToken();
                },
                child: const Text('Nouveau code',
                    style: TextStyle(color: Colors.black))),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  bool _isGeneratingToken = false;
  Future<void> _generateNewToken() async {
    final teacherId =
        Provider.of<Database>(context, listen: false).currentUser!.id;

    final passwordController = TextEditingController();
    final sure = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AreYouSureDialog(
          title: 'Générer un nouveau code ?',
          content: 'Êtes-vous certain(e) de vouloir générer un nouveau code ?\n'
              'Ceci archivera les données des élèves ayant utilisé l\'ancien code.\n\n'
              'Entrez votre mot de passe pour confirmer :',
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
      },
    );
    final password = passwordController.text;
    passwordController.dispose();
    if (!mounted) return;
    if (sure != true || password.isEmpty) {
      final scaffold = ScaffoldMessenger.of(context);
      _showSnackbar(const Text('Génération du nouveau code annulée'), scaffold);
      return;
    }

    // Check if the password is correct
    final database = Provider.of<Database>(context, listen: false);
    final loginStatus = await database.login(
        username: database.currentUser!.email,
        password: password,
        skipPostLogin: true);
    if (loginStatus != EzloginStatus.success) {
      if (mounted) {
        final scaffold = ScaffoldMessenger.of(context);
        _showSnackbar(
            const Text('Le mot de passe entré est incorrect'), scaffold);
      }
      return;
    }

    setState(() {
      _isGeneratingToken = true;
    });
    final newToken = await TeachingTokenHelpers.generateUniqueToken();
    await TeachingTokenHelpers.registerToken(teacherId, newToken);

    // Force relogin to refresh data
    if (!mounted) return;
    final username = database.currentUser!.email;
    await database.logout();
    await database.login(
        username: username, password: password, userType: UserType.teacher);

    if (!mounted) return;
    await _showCurrentToken();

    if (!mounted) return;
    RouteManager.instance.gotoStudentsPage(context);
  }

  Future<void> _showStudentInfo(User student) async {
    final database = Provider.of<Database>(context, listen: false);

    final newInfo = await showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => StudentInfoDialog(
        student: student,
        onRemoveFromList: (password) async =>
            _removeStudent(student: student, password: password),
      ),
    );
    if (newInfo == null) return;

    await database.modifyNotes(studentId: student.id, notes: newInfo);
  }

  Future<void> _removeStudent(
      {required User student, required String password}) async {
    // Check if the password is correct
    final database = Provider.of<Database>(context, listen: false);
    final loginStatus = await database.login(
        username: database.currentUser!.email,
        password: password,
        skipPostLogin: true);
    if (loginStatus != EzloginStatus.success) {
      if (mounted) {
        final scaffold = ScaffoldMessenger.of(context);
        _showSnackbar(
            const Text('Le mot de passe entré est incorrect'), scaffold);
      }
      return;
    }

    if (!mounted) return;
    final token = await TeachingTokenHelpers.createdActiveToken(
        userId: Provider.of<Database>(context, listen: false).currentUser!.id);
    if (token == null) return;
    await TeachingTokenHelpers.disconnectFromToken(student.id, token);
    if (!mounted) return;

    final username = database.currentUser!.email;
    await database.logout();
    await database.login(
        username: username, password: password, userType: UserType.teacher);
    if (!mounted) return;
    RouteManager.instance.gotoStudentsPage(context);
  }

  PreferredSizeWidget _setAppBar() {
    return ResponsiveService.appBarOf(
      context,
      title: const Text('Mes élèves'),
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        OnboardingContainer(
          onReady: (context) => onboardingContexts['generate_code'] = context,
          child: IconButton(
            onPressed: _showCurrentToken,
            icon: const Icon(Icons.qr_code_2),
            iconSize: 35,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGeneratingToken) {
      return ResponsiveService.scaffoldOf(
        context,
        appBar: _setAppBar(),
        body: Center(child: Text('Génération du code d\'inscription...')),
        smallDrawer: MainDrawer.small(),
        mediumDrawer: MainDrawer.medium(),
        largeDrawer: MainDrawer.large(),
      );
    }

    final students = Provider.of<Database>(context).students().toList();
    students.sort(
        (a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()));

    return ResponsiveService.scaffoldOf(
      context,
      key: scaffoldKey,
      appBar: _setAppBar(),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const SizedBox(height: 15),
              Text('Mon stage en images',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) => StudentListTile(
                    students[index].id,
                    modifyStudentCallback: _showStudentInfo,
                  ),
                  itemCount: students.length,
                ),
              ),
            ],
          ),
        ],
      ),
      smallDrawer: MainDrawer.small(),
      mediumDrawer: MainDrawer.medium(),
      largeDrawer: MainDrawer.large(),
    );
  }
}
