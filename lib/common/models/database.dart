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
  static const _currentDatabaseVersion = 'v0_1_0';
  static DatabaseReference get root =>
      FirebaseDatabase.instance.ref(_currentDatabaseVersion);

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
      final conntectedToken = await TeachingTokenHelpers.connectedToken(
          studentId: _currentUser!.id);
      final teacherId =
          await TeachingTokenHelpers.creatorIdOf(token: conntectedToken!);
      questions.pathToData = 'questions/$teacherId';
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
      final data = await Database.root.child(usersPath).child(id).get();
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
    final data = await Database.root.child(usersPath).get();
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
          .addAll(await TeachingTokenHelpers.userIdsConnectedTo(token: token));
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
      // await Database.root.child(usersPath).child(currentUser!.id).child('supervising')
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
    final oldQuestionsRoot = FirebaseDatabase.instance.ref('questions');
    final oldAnswersRoot = FirebaseDatabase.instance.ref('answers');
    final oldUsersRoot = FirebaseDatabase.instance.ref('users');

    // Do not migrate twice
    if (_isMigratingUser != null) return _isMigratingUser!.future;
    _isMigratingUser = Completer<bool>();
    try {
      // Copy questions to new database (no changes)
      final allQuestions = (await oldQuestionsRoot.get()).value as Map?;
      await Database.root.child('questions').set(allQuestions);

      // Prepare the answers to be migrated
      final allAnswers = (await oldAnswersRoot.get()).value as Map?;

      final users = (await oldUsersRoot.get()).value as Map?;
      // Migrate each teacher
      for (final Map teacher in users!.values) {
        // Only migrate teachers as they will automatically migrate their students
        if (teacher['userType'] != 1) continue;

        final token = await TeachingTokenHelpers.generateUniqueToken();

        // Migrate the students data
        teacher['studentNotes'] = <String, String>{};
        for (final Map student in users.values) {
          // Only migrate students supervised by this teacher
          if (student['userType'] != 2 ||
              student['supervisedBy'] != teacher['id']) {
            continue;
          }

          // Migrate the company names to student notes
          teacher['studentNotes'][student['id']] = student['companyNames'];

          // Removed obsolete fields
          student.remove('userType');
          student.remove('companyNames');
          student.remove('supervisedBy');

          // Move the answers from that student inside the connected token field
          for (final studentIds in allAnswers!.keys) {
            if (studentIds != student['id']) continue;
            allAnswers[studentIds] = {token: allAnswers[studentIds]};
            break;
          }

          // Send the student data to the new database
          await Database.root.child('users').child(student['id']).set(student);

          // Connect the student to the token
          await TeachingTokenHelpers.connectToToken(
              student['id'], teacher['id'], token);
        }

        // Removed obsolete fields
        teacher.remove('userType');
        teacher.remove('companyNames');
        teacher.remove('supervising');
        teacher.remove('supervisedBy');

        // Send the teacher data to the new database
        await Database.root.child('users').child(teacher['id']).set(teacher);

        // Register the token created by that teacher
        await TeachingTokenHelpers.registerToken(teacher['id'], token);
      }

      // Copy answers to new database
      await Database.root.child('answers').set(allAnswers);

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
