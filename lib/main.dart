import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';
import 'package:mon_stage_en_images/common/providers/speecher.dart';
import 'package:mon_stage_en_images/default_onboarding_steps.dart';
import 'package:mon_stage_en_images/onboarding/onboarding.dart';
import 'package:provider/provider.dart';

import '/firebase_options.dart';

const String softwareVersion = '1.1.1';

void main() async {
  // Set logging to INFO
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  // Initialization of the user database. If [useEmulator] is set to [true],
  // then a local database is created. To facilitate the filling of the database
  // one can create a user, login with it, then in the drawer, select the
  // 'Reinitialize the database' button.
  const useEmulator =
      bool.fromEnvironment('MSEI_USE_EMULATOR', defaultValue: false);
  await SharedPreferencesController.instance.initialize();
  final userDatabase = Database();
  await userDatabase.initialize(
      useEmulator: useEmulator,
      currentPlatform: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('fr_FR', null);
  await RouteManager.instance.initialize();

  final onboardingController = OnboardingController(
    steps: OnboardingContexts.instance.onboardingSteps,
    onOnboardStarted: () async {
      await OnboardingContexts.instance.prepareForOnboarding();
    },
    onOnboardingCompleted: () async =>
        SharedPreferencesController.instance.hasSeenTeacherOnboarding = true,
  );

  // Run the app
  runApp(MyApp(
      userDatabase: userDatabase, onboardingController: onboardingController));
}

class MyApp extends StatelessWidget {
  const MyApp(
      {super.key,
      required this.userDatabase,
      required this.onboardingController});

  final Database userDatabase;
  final OnboardingController onboardingController;

  @override
  Widget build(BuildContext context) {
    final speecher = Speecher();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => userDatabase),
        ChangeNotifierProvider(create: (context) => userDatabase.answers),
        ChangeNotifierProvider(create: (context) => userDatabase.questions),
        ChangeNotifierProvider(create: (context) => speecher),
      ],
      child: Consumer<Database>(builder: (context, database, static) {
        return MaterialApp(
          navigatorKey: RouteManager.instance.navigatorKey,
          debugShowCheckedModeBanner: false,
          initialRoute: RouteManager.instance.initialRoute,
          theme: database.userType == UserType.teacher
              ? teacherTheme()
              : studentTheme(),
          onGenerateInitialRoutes: (initialRoute) {
            return [
              MaterialPageRoute(
                settings: RouteSettings(name: initialRoute),
                builder: (context) =>
                    RouteManager.instance.builderForCurrentRoute(initialRoute),
              )
            ];
          },
          onGenerateRoute: (settings) {
            final String? routeName = settings.name;
            if (routeName == null) return null;

            return MaterialPageRoute(
                builder: (context) =>
                    RouteManager.instance.builderForCurrentRoute(routeName),
                settings: RouteSettings(
                    name: settings.name, arguments: settings.arguments));
          },
          builder: (context, child) {
            SharedPreferencesController.instance.addListener(() {
              if (!onboardingController.isOnboarding &&
                  OnboardingContexts.startingConditionAreMet(context)) {
                onboardingController.requestOnboarding();
              }
            });

            return OnboardingOverlay(
              controller: onboardingController,
              child:
                  Stack(alignment: Alignment.bottomCenter, children: [child!]),
            );
          },
        );
      }),
    );
  }
}
