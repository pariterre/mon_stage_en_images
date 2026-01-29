import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/widgets/content_card.dart';
import 'package:mon_stage_en_images/common/widgets/main_drawer.dart';
import 'package:mon_stage_en_images/screens/login/go_to_irsst_screen.dart';
import 'package:mon_stage_en_images/screens/q_and_a/main_metier_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  static const routeName = '/resources-screen';

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
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
          scaffoldKey.currentState?.openDrawer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveService.scaffoldOf(
      context,
      key: scaffoldKey,
      appBar: _setAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Text(
                  "Ressources externes pour faciliter votre utilisation de Stage en images"),
            ),
            SliverToBoxAdapter(
                child: SizedBox(
              height: 20,
            )),
            SliverList.builder(
              itemCount: resourcesCard.length,
              itemBuilder: (context, index) {
                return LimitedBox(
                  maxHeight: 300,
                  child: resourcesCard[index],
                );
              },
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

final List<ContentCard> resourcesCard = [
  ContentCard(
    title: 'Apprendre sur la SST',
    description:
        '''Une fiche produite par l'IRSST (Institut de recherche Robert-Sauvé en santé '''
        '''et en Sécurité au Travail) pour la supervision de métier semi-spécialisées''',
    primaryAction: (BuildContext context) async {
      await launchUrl(GoToIrsstScreen.learnAboutSstUri);
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    },
  ),
  ContentCard(
    title: 'Apprendre sur M.É.T.I.E.R.',
    description: '''Une publication de la chaire de recherche ADOPREVIT '''
        '''décrivant un modèle d'analyse de l'activité de travail centré sur la personne en situation.'''
        '''Ce document explore les déterminants de l'activité qui composent l'acronyme M.É.T.I.E.R. ''',
    primaryAction: (BuildContext context) async {
      await launchUrl(GoToIrsstScreen.learnAboutMetierUri);
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    },
  ),
  ContentCard(
    title: 'Exemples de questions',
    description:
        '''Une liste de questions pour les enseignantes et enseignants à utiliser pour faire'''
        ''' verbaliser l'élève sur son activité de travail au Parcours de formation axée sur'''
        ''' l’emploi (lors des visites en stage ou lors des retours réflexifs en classe).''',
    primaryAction: (BuildContext context) async {
      await launchUrl(MainMetierPage.questionIdeasUri);
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    },
  )
];
