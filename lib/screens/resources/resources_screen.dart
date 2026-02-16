import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/widgets/main_drawer.dart';
import 'package:mon_stage_en_images/default_onboarding_steps.dart';
import 'package:mon_stage_en_images/default_resources.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_container.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  static const routeName = '/resources-screen';

  @override
  State<ResourcesScreen> createState() => ResourcesScreenState();
}

class ResourcesScreenState extends State<ResourcesScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool? get isDrawerOpen => scaffoldKey.currentState?.isDrawerOpen;

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
  void closeDrawer() {
    if (isDrawerOpen != true) return;
    Navigator.of(context).pop();
  }

  PreferredSizeWidget _setAppBar() {
    return ResponsiveService.appBarOf(
      context,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.help),
          ),
          const Text('Ressources'),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () {
          openDrawer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ResponsiveService.scaffoldOf(
      context,
      key: scaffoldKey,
      appBar: _setAppBar(),
      body: OnboardingContainer(
        onInitialize: (context) =>
            OnboardingContexts.instance['resources_body'] = context,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Text(
                    "Ressources externes pour faciliter votre utilisation de Mon stage en images"),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(
                height: 20,
              )),
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing: width / 100,
                    mainAxisExtent: (width / 1.5).clamp(350, 500),
                    crossAxisCount: (width / 300).toInt().clamp(1, 3)),
                itemCount: resourcesCard.length,
                itemBuilder: (context, index) {
                  return LimitedBox(
                    maxWidth: 400,
                    maxHeight: 300,
                    child: resourcesCard[index],
                  );
                },
              ),
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
