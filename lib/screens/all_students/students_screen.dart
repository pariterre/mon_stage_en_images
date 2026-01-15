import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
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

import 'widgets/new_student_alert_dialog.dart';
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

// Static variable so the value is remembered when we come back to this screen
bool _onlyActiveStudents = true;

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

    final sure = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AreYouSureDialog(
          title: 'Générer un nouveau code ?',
          content: 'Êtes-vous certain(e) de vouloir générer un nouveau code ?\n'
              'Ceci archivera les données des élèves ayant utilisé l\'ancien code.',
        );
      },
    );
    if (!mounted) return;
    if (sure != true) {
      final scaffold = ScaffoldMessenger.of(context);
      _showSnackbar(const Text('Génération du nouveau code annulée'), scaffold);
      return;
    }

    setState(() {
      _isGeneratingToken = true;
    });
    final newToken = await TeachingTokenHelpers.generateUniqueToken();
    await TeachingTokenHelpers.registerToken(teacherId, newToken);
    if (!mounted) return;
    setState(() {
      _isGeneratingToken = false;
    });
    await _showCurrentToken();
  }

  Future<void> _modifyStudent(User student) async {
    final database = Provider.of<Database>(context, listen: false);
    final scaffold = ScaffoldMessenger.of(context);

    final newInfo = await showDialog<User>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return NewStudentAlertDialog(
          student: student,
          deleteCallback: _removeStudent,
        );
      },
    );
    if (newInfo == null) return;

    final status = await database.modifyStudent(newInfo: newInfo);
    switch (status) {
      case EzloginStatus.success:
        return;
      case EzloginStatus.userNotFound:
        _showSnackbar(
            const Text(
                'L\'élève n\'a pas été trouvé(e) dans la base de donnée'),
            scaffold);
        return;
      default:
        _showSnackbar(
            const Text('Erreur inconnue lors de la modification de l\'élève'),
            scaffold);
        return;
    }
  }

  Future<void> _removeStudent(User student) async {
    final scaffold = ScaffoldMessenger.of(context);
    final database = Provider.of<Database>(context, listen: false);

    final sure = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AreYouSureDialog(
          title: 'Suppression des données d\'un élève',
          content:
              'Êtes-vous certain(e) de vouloir supprimer les données de $student?',
        );
      },
    );

    if (!sure!) {
      _showSnackbar(const Text('Suppression de l\'élève annulée'), scaffold);
      return;
    }

    final studentUser = await database.user(student.email);
    if (studentUser == null) return;
    var status = await database.deleteUser(user: studentUser);
    if (status != EzloginStatus.success) {
      _showSnackbar(
          const Text('La supression d\'élève n\'est pas encore disponible.'),
          scaffold);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    if (!(database.currentUser?.isActive ?? false) || _isGeneratingToken) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final students = Provider.of<Database>(context)
        .students(onlyActive: _onlyActiveStudents)
        .toList();
    students.sort(
        (a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()));
    students.sort((a, b) => a.isActive && b.isNotActive
        ? -1
        : a.isNotActive && b.isActive
            ? 1
            : 0);

    return ResponsiveService.scaffoldOf(
      context,
      key: scaffoldKey,
      appBar: ResponsiveService.appBarOf(
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
            onReady: (context) => onboardingContexts['add_student'] = context,
            child: IconButton(
              onPressed: _showCurrentToken,
              icon: const Icon(Icons.qr_code_2),
              iconSize: 35,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const SizedBox(height: 15),
              Text('Mon stage en images',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              // TODO Re-add this when archiving is implemented?
              // Align(
              //     alignment: Alignment.topRight,
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Text('Afficher les élèves archivés'),
              //         SizedBox(width: 10),
              //         Switch(
              //             onChanged: (value) =>
              //                 setState(() => _onlyActiveStudents = !value),
              //             value: !_onlyActiveStudents),
              //       ],
              //     )),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) => StudentListTile(
                    students[index].id,
                    modifyStudentCallback: _modifyStudent,
                  ),
                  itemCount: students.length,
                ),
              ),
            ],
          ),
        ],
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
    );
  }
}
