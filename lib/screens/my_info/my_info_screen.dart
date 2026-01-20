import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/helpers/shared_preferences_manager.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/widgets/main_drawer.dart';
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

    switch (Provider.of<Database>(context, listen: false).userType) {
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
    final user = Provider.of<Database>(context, listen: false).currentUser!;

    return ResponsiveService.scaffoldOf(
      context,
      key: scaffoldKey,
      appBar: _setAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Text('Mes informations',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Row(
              children: [
                Text('Nom, prénom : ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${user.firstName} ${user.lastName}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Courriel : ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(user.email),
              ],
            ),
          ],
        ),
      ),
      smallDrawer: MainDrawer.small(),
      mediumDrawer: MainDrawer.medium(),
      largeDrawer: MainDrawer.large(),
    );
  }
}
