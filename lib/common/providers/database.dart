import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ezlogin/ezlogin.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireauth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/common/helpers/emoji_helpers.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/helpers/teaching_token_helpers.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/question.dart';
import 'package:mon_stage_en_images/common/models/suggestion.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_questions.dart';
import 'package:mon_stage_en_images/common/providers/all_student_answers.dart';
import 'package:mon_stage_en_images/common/providers/all_teacher_answers.dart';

export 'package:ezlogin/ezlogin.dart';

final _logger = Logger('Database');

class Database extends EzloginFirebase with ChangeNotifier {
  ///
  /// This is an internal structure to quickly access the current
  /// user information. These may therefore be out of sync with the database

  static const String _userPathInternal = 'users';
  Database({required this.onConnectionStateChanged})
      : super(usersPath: '$_currentDatabaseVersion/$_userPathInternal');

  // Rerefence to the database provider
  final Function(bool isActive) onConnectionStateChanged;
  late final questions =
      AllQuestions(onConnectionStateChanged: onConnectionStateChanged);
  final teacherAnswers = AllTeacherAnswers();
  final studentAnswers = AllStudentAnswers();

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
    Future<String?> Function()? getOldPassword,
    Future<String?> Function()? getNewPassword,
    UserType userType = UserType.none,
    bool skipPostLogin = false,
    Function()? onNewTeacherConnected,
  }) async {
    final status = await super.login(
        username: username,
        password: password,
        getNewUserInfo: getNewUserInfo,
        getNewPassword: getNewPassword);
    if (skipPostLogin || status != EzloginStatus.success) return status;
    _fromAutomaticLogin = false;
    await _postLogin(
        userType: userType, onNewTeacherConnected: onNewTeacherConnected);
    return status;
  }

  Future<void> _postLogin(
      {UserType? userType, Function()? onNewTeacherConnected}) async {
    _currentUser = await user(fireauth.FirebaseAuth.instance.currentUser!.uid);

    SharedPreferencesController.instance.userType =
        userType ?? SharedPreferencesController.instance.userType;

    // For teachers, ensure they have an active token (i.e. they are new), otherwise create one
    if (userType == UserType.teacher &&
        await TeachingTokenHelpers.createdActiveToken(
                userId: _currentUser!.id) ==
            null) {
      final token = await TeachingTokenHelpers.generateUniqueToken();
      await TeachingTokenHelpers.registerToken(_currentUser!.id, token);
      if (onNewTeacherConnected != null) await onNewTeacherConnected();
    }

    await fetchUsers();
    await _startFetchingData();

    notifyListeners();
  }

  Future<void> _startFetchingData() async {
    if (_currentUser == null) return;
    // this should be call only after user has successfully logged in

    questions.pathToData = '';
    teacherAnswers.pathToData = '';
    teacherAnswers.connectedStudents = null;
    studentAnswers.pathToData = '';
    studentAnswers.studentUser = null;
    switch (userType) {
      case UserType.none:
        break;
      case UserType.student:
        {
          final token = await TeachingTokenHelpers.connectedToken(
              studentId: _currentUser!.id);
          if (token == null) break;

          final teacherId =
              await TeachingTokenHelpers.creatorIdOf(token: token);
          await studentAnswers.initializeFetchingData(
              pathToData:
                  '$_currentDatabaseVersion/answers/$token/${_currentUser!.id}',
              studentUser: _currentUser!);
          await questions.initializeFetchingData(
              pathToData: '$_currentDatabaseVersion/questions/$teacherId');
          break;
        }
      case UserType.teacher:
        {
          final token = await TeachingTokenHelpers.createdActiveToken(
              userId: _currentUser!.id);
          if (token == null) break;
          await teacherAnswers.initializeFetchingData(
            pathToData: '$_currentDatabaseVersion/answers/$token',
            connectedStudents: students,
          );
          await questions.initializeFetchingData(
              pathToData:
                  '$_currentDatabaseVersion/questions/${_currentUser!.id}');
        }
    }
  }

  Future<void> _stopFetchingData() async {
    await teacherAnswers.stopFetchingData();
    await studentAnswers.stopFetchingData();
    await questions.stopFetchingData();
  }

  Future<void> restartFetchingTeacherAnswers() async {
    if (_currentUser == null || userType != UserType.teacher) return;

    final token =
        await TeachingTokenHelpers.createdActiveToken(userId: _currentUser!.id);
    if (token == null) return;

    await teacherAnswers.stopFetchingData();
    await teacherAnswers.initializeFetchingData(
      pathToData: '$_currentDatabaseVersion/answers/$token',
      connectedStudents: students,
    );
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
    // Get a copy of current tokens before modification (as they will be lost and needs to be updated)
    final tokens = (await Database.root
            .child('users')
            .child(user.id)
            .child('tokens')
            .get())
        .value as Map?;
    final status = await super.modifyUser(user: user, newInfo: newInfo);
    // Restore tokens after modification
    if (tokens != null) {
      await Database.root
          .child('users')
          .child(user.id)
          .child('tokens')
          .set(tokens);

      await TeachingTokenHelpers.updatePublicInformation(user.id);
    }
    if (user.email == currentUser?.email) {
      _currentUser = await this.user(user.id);
      notifyListeners();
    }
    return status;
  }

  @override
  Future<User?> user(String id) async {
    try {
      final data = await Database.root.child(_userPathInternal).child(id).get();
      if (data.value == null) {
        // If no data are found in the current version, try to migrate from previous version
        try {
          // Try writing a value to ensure we have access to the new database
          try {
            await FirebaseDatabase.instance
                .ref('admin')
                .child('tester')
                .set(true);
            await FirebaseDatabase.instance
                .ref('admin')
                .child('tester')
                .remove();
            await _DatabaseMigrationHelper.migrateFromVersion0_0_0();
            logout();
            return null; // Migration is done, force reset
          } on Exception {
            // This is not a user who is suppose to migrate, ignore
          }
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
    final data = await Database.root.child(_userPathInternal).get();
    if (data.value == null) return null;

    final userdata =
        (data.value as Map).values.firstWhere((e) => e['email'] == email);
    if (userdata == null) return null;

    return User.fromSerialized(userdata);
  }

  final List<User> _users = [];
  List<User> get users => [..._users];
  List<User> get students {
    if (_currentUser == null) return [];

    return switch (userType) {
      UserType.none => [],
      UserType.student =>
        _users.where((e) => e.id == _currentUser!.id).toList(),
      UserType.teacher => _users.where((e) => e.id != _currentUser!.id).toList()
    };
  }

  User? userById(String? id) {
    if (id == _currentUser?.id) return _currentUser;
    return id == null ? null : _users.firstWhereOrNull((user) => user.id == id);
  }

  User? studentById(String? id) {
    if (id == _currentUser?.id) return _currentUser;
    return id == null
        ? null
        : students.firstWhereOrNull((student) => student.id == id);
  }

  User? get teacher {
    if (_currentUser == null) return null;

    return switch (userType) {
      UserType.none => null,
      UserType.student =>
        _users.firstWhereOrNull((e) => e.id != _currentUser!.id),
      UserType.teacher => _currentUser,
    };
  }

  Future<void> sendSuggestion({required Suggestion suggestion}) async {
    if (_currentUser == null) return;
    await Database.root
        .child('suggestions')
        .child(currentUser!.id)
        .child(suggestion.id)
        .set(suggestion.serialize());
  }

  ///
  /// This method should be called when a student connects to a teacher.
  Future<void> initializeAnswersDatabase(
      {required String studentId, required String token}) async {
    // Make sure we have everything set up to fetch questions and send answers before proceeding
    final token =
        await TeachingTokenHelpers.connectedToken(studentId: _currentUser!.id);
    if (token == null) return;

    final teacherId = await TeachingTokenHelpers.creatorIdOf(token: token);
    if (teacherId == null) return;

    // Fetch all questions from that teacher
    final data = await root.child('questions').child(teacherId).get();
    if (data.value == null) return;
    final questionsData = data.value as Map?;
    if (questionsData == null) return;
    final questions = questionsData.values
        .map((q) => Question.fromSerialized((q as Map).cast<String, dynamic>()))
        .toList();

    // Reconfigure answers database provider
    await studentAnswers.stopFetchingData();
    await studentAnswers.initializeFetchingData(
        pathToData: '$_currentDatabaseVersion/answers/$token/$studentId',
        studentUser: _currentUser!);

    // Wait while answers are fetched
    await Future.delayed(const Duration(milliseconds: 2000));

    // Check if answers already exist for that student (reconnected student)
    questions.removeWhere(
        (q) => studentAnswers.any((a) => a.questionId == q.id) == true);

    // Send the answers to the database
    await studentAnswers.addAnswers(questions.map((e) => Answer(
          isActive: false,
          actionRequired: ActionRequired.fromStudent,
          createdById: teacherId,
          studentId: studentId,
          questionId: e.id,
        )));
  }

  Future<void> fetchUsers() async {
    if (_currentUser == null) return;

    _users.clear();
    _users.add((await user(_currentUser!.id))!);

    switch (userType) {
      case UserType.none:
        break;
      case UserType.student:
        {
          final token = await TeachingTokenHelpers.connectedToken(
              studentId: _currentUser!.id);
          if (token == null) break;
          final teacherId =
              await TeachingTokenHelpers.creatorIdOf(token: token);
          if (teacherId == null) break;
          final teacher =
              await TeachingTokenHelpers.getPublicInformation(teacherId, token);
          if (teacher == null ||
              teacher['avatar'] == null ||
              teacher['firstName'] == null ||
              teacher['lastName'] == null) {
            break;
          }

          _users.add(User.limitedUser(
              id: teacherId,
              avatar: teacher['avatar'],
              firstName: teacher['firstName'],
              lastName: teacher['lastName']));
          break;
        }
      case UserType.teacher:
        {
          final token = await TeachingTokenHelpers.createdActiveToken(
              userId: _currentUser!.id);

          final connectedStudentIds = token == null
              ? <String>[]
              : await TeachingTokenHelpers.userIdsConnectedTo(token: token);

          for (final id in connectedStudentIds) {
            final student = await user(id);
            if (student != null) _users.add(student);
          }
        }
    }

    notifyListeners();
  }

  Future<bool> modifyNotes(
      {required String studentId, required String notes}) async {
    if (currentUser == null) return false;

    currentUser!.studentNotes[studentId] = notes;
    final status = await modifyUser(user: currentUser!, newInfo: currentUser!);
    return status == EzloginStatus.success;
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

        // Add an avatar to the teacher
        teacher['avatar'] = EmojiHelpers.randomEmoji;

        final token = await TeachingTokenHelpers.generateUniqueToken();
        allAnswers?[token] = {};

        // Migrate the students data
        teacher['studentNotes'] = <String, String>{};
        for (final Map student in users.values) {
          // Only migrate students supervised by this teacher
          if (student['userType'] != 2 ||
              student['supervisedBy'] != teacher['id']) {
            continue;
          }

          // Add an avatar to the student
          student['avatar'] = EmojiHelpers.randomEmoji;

          // Migrate the company names to student notes
          teacher['studentNotes'][student['id']] = student['companyNames'];

          // Removed obsolete fields
          student.remove('userType');
          student.remove('companyNames');
          student.remove('supervisedBy');

          // Move the answers from that student inside the connected token field
          for (final studentId in allAnswers!.keys) {
            if (studentId != student['id']) continue;
            allAnswers[token][student['id']] = allAnswers[studentId];

            for (final answers
                in ((allAnswers[token][student['id']] as Map?)?.values ?? [])) {
              if (answers is! Map) continue;
              if (answers.containsKey('discussion')) {
                for (final message in (answers['discussion'] as Map).values) {
                  if (message is! Map) continue;
                  message['studentId'] = student['id'];
                  message.remove('name');
                }
              }
            }

            allAnswers.remove(studentId);
            break;
          }

          // Send the student data to the new database
          await Database.root.child('users').child(student['id']).set(student);

          // Connect the student to the token
          await TeachingTokenHelpers.connectToToken(
              token: token, studentId: student['id'], teacherId: teacher['id']);
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
