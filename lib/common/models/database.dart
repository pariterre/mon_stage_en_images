import 'dart:async';

import 'package:ezlogin/ezlogin.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireauth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/helpers/teaching_token_helpers.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_answers.dart';
import 'package:mon_stage_en_images/common/providers/all_questions.dart';

export 'package:ezlogin/ezlogin.dart';

final _logger = Logger('Database');

class Database extends EzloginFirebase with ChangeNotifier {
  ///
  /// This is an internal structure to quickly access the current
  /// user information. These may therefore be out of sync with the database

  // Rerefence to the database providers
  final questions = AllQuestions();
  final answers = AllAnswers();

  static const defaultStudentPassword = 'monStage';
  static const currentDatabaseVersion = 'v0_1_0';

  bool _fromAutomaticLogin = false;
  bool get fromAutomaticLogin => _fromAutomaticLogin;
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  UserType get userType => SharedPreferencesController.instance.userType;

  @override
  Future<void> initialize({bool useEmulator = false, currentPlatform}) async {
    final status = await super
        .initialize(useEmulator: useEmulator, currentPlatform: currentPlatform);

    if (super.currentUser != null) {
      _fromAutomaticLogin = true;
      await _postLogin();
    }
    return status;
  }

  @override
  Future<EzloginStatus> login({
    required String username,
    required String password,
    Future<EzloginUser?> Function()? getNewUserInfo,
    Future<String?> Function()? getNewPassword,
    UserType userType = UserType.none,
  }) async {
    final status = await super.login(
        username: username,
        password: password,
        getNewUserInfo: getNewUserInfo,
        getNewPassword: getNewPassword);
    if (status != EzloginStatus.success) return status;
    _fromAutomaticLogin = false;
    await _postLogin(userType: userType);
    return status;
  }

  Future<void> _postLogin({UserType? userType}) async {
    _currentUser = await user(fireauth.FirebaseAuth.instance.currentUser!.uid);
    SharedPreferencesController.instance.userType =
        userType ?? SharedPreferencesController.instance.userType;

    await _fetchConnectedStudents();
    await _startFetchingData();

    notifyListeners();
  }

  Future<void> _startFetchingData() async {
    /// this should be call only after user has successfully logged in

    await answers.initializeFetchingData();

    if (userType == UserType.student) {
      questions.pathToData =
          'questions/Tata'; // TODO THIS ${_currentUser!.supervisedBy}';
    } else {
      questions.pathToData = 'questions/${_currentUser!.id}';
    }
    await questions.initializeFetchingData();
  }

  Future<void> _stopFetchingData() async {
    await answers.stopFetchingData();
    await questions.stopFetchingData();
  }

  @override
  Future<EzloginStatus> logout() async {
    _currentUser = null;
    await _stopFetchingData();
    notifyListeners();
    _fromAutomaticLogin = false;
    return super.logout();
  }

  @override
  Future<EzloginStatus> modifyUser(
      {required EzloginUser user, required EzloginUser newInfo}) async {
    final status = await super.modifyUser(user: user, newInfo: newInfo);
    if (user.email == currentUser?.email) {
      _currentUser = await this.user(user.id);
      notifyListeners();
    }
    return status;
  }

  @override
  Future<User?> user(String id) async {
    try {
      final data = await FirebaseDatabase.instance
          .ref('$currentDatabaseVersion/$usersPath/$id')
          .get();
      if (data.value == null) {
        // If no data are found in the current version, try to migrate from previous version
        try {
          await _DatabaseMigrationHelper.migrateFromVersion0_0_0();
          return null; // Migration is done, force reset
        } on Exception catch (error) {
          _logger.severe(
              'Error while migrating ({$error}) user $id from old database version');
          return null;
        }
      }

      return data.value == null
          ? null
          : User.fromSerialized((data.value as Map?)?.cast<String, dynamic>());
    } on Exception catch (error, stackTrace) {
      _logger.severe('Error while fetching ({$error}) user $id', stackTrace);
      return null;
    }
  }

  @override
  Future<User?> userFromEmail(String email) async {
    final data = await FirebaseDatabase.instance.ref(usersPath).get();
    if (data.value == null) return null;

    final userdata =
        (data.value as Map).values.firstWhere((e) => e['email'] == email);
    if (userdata == null) return null;

    return User.fromSerialized(userdata);
  }

  final List<User> _connectedStudents = [];
  Iterable<User> students({bool onlyActive = true}) {
    return onlyActive
        ? _connectedStudents.where((s) => s.isActive)
        : [..._connectedStudents];
  }

  Future<void> _fetchConnectedStudents() async {
    if (_currentUser == null) return;

    final tokens = (await TeachingTokenHelpers.createdTokens(
            userId: _currentUser!.id, activeOnly: true))
        .toList();

    final connectedStudentIds = <String>{};
    for (final token in tokens) {
      connectedStudentIds
          .addAll(await TeachingTokenHelpers.connectedUserIdsTo(token: token));
    }

    for (final id in connectedStudentIds) {
      final student = await user(id);
      if (student != null) _connectedStudents.add(student);
    }

    notifyListeners();
  }

  Future<EzloginStatus> addStudent(
      {required User newStudent,
      required AllQuestions questions,
      required AllAnswers answers}) async {
    if (_fromAutomaticLogin) return EzloginStatus.needAuthentication;

    var newUser =
        await addUser(newUser: newStudent, password: defaultStudentPassword);
    if (newUser == null) return EzloginStatus.alreadyCreated;

    newStudent = newStudent.copyWith(id: newUser.id);
    // TODO THIS
    //currentUser!.supervising[newStudent.id] = true;

    try {
      // await FirebaseDatabase.instance
      //     .ref('$usersPath/${currentUser!.id}/supervising')
      //     .set(currentUser!.supervising);
    } on Exception {
      return EzloginStatus.unrecognizedError;
    }

    try {
      answers.addAnswers(questions.map((e) => Answer(
            isActive: e.defaultTarget == Target.all,
            actionRequired: ActionRequired.fromStudent,
            createdById: currentUser!.id,
            studentId: newStudent.id,
            questionId: e.id,
          )));
    } on Exception {
      return EzloginStatus.unrecognizedError;
    }

    //_fetchStudents(); // TODO THIS
    return EzloginStatus.success;
  }

  Future<EzloginStatus> modifyStudent({required User newInfo}) async {
    final studentUser = await user(newInfo.id);
    if (studentUser == null) return EzloginStatus.userNotFound;

    final status = await modifyUser(user: studentUser, newInfo: newInfo);
    //_fetchStudents(); // TODO THIS
    return status;
  }

  static Future<String?> getRequiredSoftwareVersion() async {
    final data =
        await FirebaseDatabase.instance.ref('appInfo/requiredVersion').get();
    return data.value as String?;
  }

  @override
  Future<bool> resetPassword({String? email}) async {
    if (email == null) return false;
    return await super.resetPassword(email: email);
  }
}

class _DatabaseMigrationHelper {
  static Completer<bool>? _isMigratingUser;

  static Future<bool> migrateFromVersion0_0_0() async {
    // Do not migrate twice
    if (_isMigratingUser != null) return _isMigratingUser!.future;
    _isMigratingUser = Completer<bool>();
    try {
      final users =
          (await FirebaseDatabase.instance.ref('users').get()).value as Map?;

      // Add the connexion token
      for (final Map teacher in users!.values) {
        // Only migrate teachers as they will automatically migrate their students
        if (teacher['userType'] != 1) continue;

        final token =
            await TeachingTokenHelpers.registerNewTeachingToken(teacher['id']);

        // Migrate the students data
        teacher['studentNotes'] = <String, String>{};
        for (final Map student in users.values) {
          // Only migrate students supervised by this teacher
          if (student['userType'] != 2 ||
              student['supervisedBy'] != teacher['id']) {
            continue;
          }

          // Add the connected token to the student
          await TeachingTokenHelpers.connectToTeachingToken(
              student['id'], teacher['id'], token);

          // Migrate the company names to student notes
          teacher['studentNotes'][student['id']] = student['companyNames'];

          // Removed obsolete fields
          student.remove('userType');
          student.remove('companyNames');
          student.remove('supervisedBy');

          // Send the student data to the new database
          await FirebaseDatabase.instance
              .ref('${Database.currentDatabaseVersion}/users/${student['id']}')
              .set(student);
        }

        // Removed obsolete fields
        teacher.remove('userType');
        teacher.remove('companyNames');
        teacher.remove('supervising');
        teacher.remove('supervisedBy');

        // Send the teacher data to the new database
        await FirebaseDatabase.instance
            .ref('${Database.currentDatabaseVersion}/users/${teacher['id']}')
            .set(teacher);
      }

      // Copy question to new database
      final questions = (await FirebaseDatabase.instance.ref('questions').get())
          .value as Map?;
      await FirebaseDatabase.instance
          .ref('${Database.currentDatabaseVersion}/questions')
          .set(questions);

      // Copy answers to new database
      final answers =
          (await FirebaseDatabase.instance.ref('answers').get()).value as Map?;
      await FirebaseDatabase.instance
          .ref('${Database.currentDatabaseVersion}/answers')
          .set(answers);

      // Migration done
      _isMigratingUser?.complete(true);

      return true;
    } on Exception catch (error, stackTrace) {
      _logger.severe(
          'Error while migrating ({$error}) user from old database version',
          stackTrace);
      _isMigratingUser?.complete(false);
      return false;
    }
  }
}
