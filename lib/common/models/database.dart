import 'dart:async';

import 'package:ezlogin/ezlogin.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireauth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
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

  bool _fromAutomaticLogin = false;
  bool get fromAutomaticLogin => _fromAutomaticLogin;
  User? _currentUser;

  final Map<String, Map<String, int>> _teachingTokens = {};
  String? activeTeachingToken({required String teacherId}) {
    // TODO: Check first is the most indeed the most recent token
    return _teachingTokens[teacherId]?.keys.first;
  }

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

    _teachingTokens.clear();
    _teachingTokens.addAll(await _fetchTeachingTokens());
    await _fetchConnectedStudents(
        activeTeachingToken(teacherId: _currentUser!.id));
    await _startFetchingData();

    notifyListeners();
  }

  static Future<Map<String, Map<String, int>>> _fetchTeachingTokens() async {
    Map<String, int> sortedTokens(Map<String, int> tokens) {
      return Map.fromEntries(
        [...tokens.entries]..sort((a, b) => b.value.compareTo(a.value)),
      );
    }

    final Map<String, Map<String, int>> teachingTokens = {};
    final data = await FirebaseDatabase.instance
        .ref('$_currentDatabaseVersion/teachingTokens')
        .get();
    for (final MapEntry teacherTokenEntry
        in (data.value as Map?)?.entries ?? []) {
      final String teacherId = teacherTokenEntry.key;
      final Map<String, int> teacherTokens = sortedTokens(
          (teacherTokenEntry.value as Map?)?.cast<String, int>() ?? {});

      teachingTokens[teacherId] = teacherTokens;
    }
    return teachingTokens;
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
    _teachingTokens.clear();
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
          .ref('$_currentDatabaseVersion/$usersPath/$id')
          .get();
      if (data.value == null) {
        // If no data are found in the current version, try to migrate from previous version
        try {
          final isSuccess =
              await _DatabaseMigrationHelper.migrateFromVersion0_0_0();
          return isSuccess ? await user(id) : null;
        } on Exception catch (error) {
          _logger.severe(
              'Error while migrating ({$error}) user $id from old database version');
          return null;
        }
      }

      return data.value == null
          ? null
          : User.fromSerialized((data.value as Map?)?.cast<String, dynamic>());
    } on Exception catch (error) {
      _logger.severe('Error while fetching ({$error}) user $id');
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

  Future<void> _fetchConnectedStudents(String? activeTeachingToken) async {
    if (_currentUser == null || activeTeachingToken == null) return;
    // TODO Make the proper rules for safety
    late final DataSnapshot data;
    try {
      data = await FirebaseDatabase.instance
          .ref('$usersPath/${_currentUser!.id}')
          .get();
    } on Exception {
      _logger.severe('Error while fetching user ${_currentUser!.id}');
      return;
    }

    _students.clear();

    if (data.value != null) {
      for (final id
          in ((data.value! as Map)['supervising'] as Map? ?? {}).keys) {
        final student = await user(id);
        if (student != null) _students.add(student);
      }
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

  ///
  /// Generate a 6-character token that is not already in the database
  static Future<String> generateUniqueTeachingToken() async {
    final teachingTokens = await Database._fetchTeachingTokens();
    final existingTeachingTokens = <String>{};
    for (final Map<String, int> tokens in teachingTokens.values) {
      existingTeachingTokens.addAll(tokens.keys);
    }

    const chars = 'ABCDEFGHJKMNPQRSTUVXY3456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    String token;
    do {
      token = List.generate(6, (index) {
        final indexChar = (rand + index * 37) % chars.length;
        return chars[indexChar];
      }).join();
    } while (existingTeachingTokens.contains(token));

    return token;
  }
}

class _DatabaseMigrationHelper {
  static Completer<bool>? _isMigratingUser;

  static Future<bool> migrateFromVersion0_0_0() async {
    final currentId = fireauth.FirebaseAuth.instance.currentUser!.uid;
    try {
      // Do not migrate other than the current user that is a teacher
      if (currentId != 'jB7HOWzcTy4tavFafMYh5HMvLNEx') return false;
      final users =
          (await FirebaseDatabase.instance.ref('users').get()).value as Map?;

      // Do not migrate twice
      if (_isMigratingUser != null) return _isMigratingUser!.future;
      _isMigratingUser = Completer<bool>();

      // Add the connexion token
      for (final Map teacher in users!.values) {
        // Only migrate teachers as they will automatically migrate their students
        if (teacher['userType'] != 1) continue;

        final token = await Database.generateUniqueTeachingToken();
        await FirebaseDatabase.instance
            .ref('${Database._currentDatabaseVersion}/teachingTokens')
            .child(teacher['id'])
            .child(token)
            .set(DateTime.now().millisecondsSinceEpoch);

        // Migrate the students data
        teacher['studentNotes'] = <String, String>{};
        for (final Map student in users.values) {
          // Only migrate students supervised by this teacher
          if (student['userType'] != 2 ||
              student['supervisedBy'] != teacher['id']) {
            continue;
          }

          // Add the connected token to the student
          student['connectedTokens'] = {token: true};

          // Migrate the company names to student notes
          teacher['studentNotes'][student['id']] = student['companyNames'];

          // Removed obsolete fields
          student.remove('userType');
          student.remove('companyNames');
          student.remove('supervisedBy');

          // Send the student data to the new database
          await FirebaseDatabase.instance
              .ref('${Database._currentDatabaseVersion}/users/${student['id']}')
              .set(student);
        }

        // Removed obsolete fields
        teacher.remove('userType');
        teacher.remove('companyNames');
        teacher.remove('supervising');
        teacher.remove('supervisedBy');

        // Send the teacher data to the new database
        await FirebaseDatabase.instance
            .ref('${Database._currentDatabaseVersion}/users/${teacher['id']}')
            .set(teacher);
      }
      // Migration done
      _isMigratingUser?.complete(true);
      _isMigratingUser = null;

      return true;
    } on Exception catch (error, stackTrace) {
      _logger.severe(
          'Error while migrating ({$error}) user from old database version',
          stackTrace);
      _isMigratingUser?.complete(false);
      _isMigratingUser = null;
      return false;
    }
  }
}
