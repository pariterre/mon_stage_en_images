import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
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
    final user = Provider.of<Database>(context, listen: false).currentUser;
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
                        onPressed: () {},
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
