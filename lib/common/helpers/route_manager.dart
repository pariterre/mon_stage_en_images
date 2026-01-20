import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/main.dart';
import 'package:mon_stage_en_images/screens/all_students/students_screen.dart';
import 'package:mon_stage_en_images/screens/login/go_to_irsst_screen.dart';
import 'package:mon_stage_en_images/screens/login/login_screen.dart';
import 'package:mon_stage_en_images/screens/login/terms_and_services_screen.dart';
import 'package:mon_stage_en_images/screens/login/wrong_version_screen.dart';
import 'package:mon_stage_en_images/screens/my_info/my_info_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/q_and_a_screen.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';

class RouteManager {
  // Singleton pattern
  RouteManager._();
  static final RouteManager instance = RouteManager._();

  bool get isInitialized => _versionIsValid != null;

  bool? _versionIsValid;
  Future<void> initialize() async {
    await _setVersionIsValid();
  }

  Future<void> _setVersionIsValid() async {
    // Check the software version
    final requiredVersion =
        Version.parse(await Database.getRequiredSoftwareVersion() ?? '0.0.0');
    final current = Version.parse(softwareVersion);
    _versionIsValid = current >= requiredVersion;
  }

  final _navigatorKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  NavigatorState? get currentState => _navigatorKey.currentState;

  String get initialRoute {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    if (_versionIsValid!) {
      return LoginScreen.routeName;
    } else {
      return WrongVersionScreen.routeName;
    }
  }

  Future<void> gotoLoginPage(BuildContext context) async {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    await currentState?.pushReplacementNamed(LoginScreen.routeName);
  }

  Future<void> gotoTermsAndServicesPage(BuildContext context) async {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    if (currentState == null) return;

    final areTermsAccepted = Provider.of<Database>(context, listen: false)
        .currentUser!
        .termsAndServicesAccepted;

    if (!areTermsAccepted) {
      await currentState
          ?.pushReplacementNamed(TermsAndServicesScreen.routeName);
    } else {
      await gotoIrsstPage(context);
    }
  }

  Future<void> gotoIrsstPage(BuildContext context) async {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    if (currentState == null) return;
    final userType = Provider.of<Database>(context, listen: false).userType;
    switch (userType) {
      case UserType.student:
        await gotoQAndAPage(context,
            target: Target.individual,
            pageMode: PageMode.editableView,
            student: null);
        break;
      case UserType.teacher:
      case UserType.none:
        if (SharedPreferencesController.instance.hasAlreadySeenTheIrrstPage) {
          await gotoStudentsPage(context);
        } else {
          await currentState?.pushReplacementNamed(GoToIrsstScreen.routeName);
        }
        break;
    }
  }

  Future<void> gotoMyInfoPage(BuildContext context) async {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    await currentState?.pushReplacementNamed(MyInfoScreen.routeName);
  }

  Future<void> gotoStudentsPage(BuildContext context) async {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    await currentState?.pushReplacementNamed(StudentsScreen.routeName);
  }

  Future<void> gotoQAndAPage(
    BuildContext context, {
    required Target target,
    required PageMode pageMode,
    required User? student,
  }) async {
    if (!isInitialized) {
      throw Exception(
          'RouteManager is not initialized. Call initialize() before accessing initialRoute.');
    }

    await currentState?.pushReplacementNamed(
      QAndAScreen.routeName,
      arguments: [target, pageMode, student],
    );
  }

  Widget builderForCurrentRoute(String routeName) {
    switch (routeName) {
      case MyInfoScreen.routeName:
        return MyInfoScreen();
      case WrongVersionScreen.routeName:
        return WrongVersionScreen();
      case LoginScreen.routeName:
        return LoginScreen();
      case TermsAndServicesScreen.routeName:
        return TermsAndServicesScreen();
      case GoToIrsstScreen.routeName:
        return GoToIrsstScreen();
      case StudentsScreen.routeName:
        return StudentsScreen();
      case QAndAScreen.routeName:
        return QAndAScreen();
      default:
        return SizedBox.shrink();
    }
  }
}
