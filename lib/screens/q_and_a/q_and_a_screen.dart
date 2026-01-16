import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/helpers/route_manager.dart';
import 'package:mon_stage_en_images/common/helpers/teaching_token_helpers.dart';
import 'package:mon_stage_en_images/common/models/answer_sort_and_filter.dart';
import 'package:mon_stage_en_images/common/models/database.dart';
import 'package:mon_stage_en_images/common/models/enum.dart';
import 'package:mon_stage_en_images/common/models/section.dart';
import 'package:mon_stage_en_images/common/models/text_reader.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:mon_stage_en_images/common/widgets/main_drawer.dart';
import 'package:mon_stage_en_images/default_onboarding_steps.dart';
import 'package:mon_stage_en_images/onboarding/widgets/onboarding_container.dart';
import 'package:mon_stage_en_images/screens/q_and_a/main_metier_page.dart';
import 'package:mon_stage_en_images/screens/q_and_a/question_and_answer_page.dart';
import 'package:mon_stage_en_images/screens/q_and_a/widgets/filter_answers_dialog.dart';
import 'package:mon_stage_en_images/screens/q_and_a/widgets/metier_app_bar.dart';
import 'package:provider/provider.dart';

class QAndAScreen extends StatefulWidget {
  const QAndAScreen({
    super.key,
  });

  static const String routeName = '/q-and-a-screen';

  @override
  State<QAndAScreen> createState() => QAndAScreenState();
}

class QAndAScreenState extends State<QAndAScreen> {
  bool _isInitialized = false;
  User? _student;
  Target _viewSpan = Target.individual;
  PageMode _pageMode = PageMode.fixView;
  var _answerFilter = AnswerSortAndFilter();

  final _pageController = PageController();
  var _currentPage = 0;
  VoidCallback? _switchQuestionModeCallback;

  String? _currentToken;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initializeCurrentToken());
  }

  Future<void> _initializeCurrentToken() async {
    final database = Provider.of<Database>(context, listen: false);
    final userId = database.currentUser?.id;
    if (userId == null) return;
    _currentToken = switch (database.userType) {
      UserType.teacher =>
        await TeachingTokenHelpers.createdActiveToken(userId: userId),
      UserType.student =>
        await TeachingTokenHelpers.connectedToken(studentId: userId),
      UserType.none => null,
    };
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;
    final database = Provider.of<Database>(context, listen: false);
    final userType = database.userType;

    final currentUser = database.currentUser;

    final arguments = ModalRoute.of(context)!.settings.arguments as List?;
    _viewSpan = arguments?[0] as Target? ?? _viewSpan;
    _pageMode = arguments?[1] as PageMode? ?? _pageMode;
    _student =
        userType == UserType.student ? currentUser : arguments?[2] as User?;
    setState(() {});

    _isInitialized = true;
  }

  void onPageChanged(BuildContext context, int page) {
    final userType = Provider.of<Database>(context, listen: false).userType;

    _currentPage = page;
    // On the main question page, if it is the teacher on a single student, then
    // back brings back to the student page. Otherwise, it opens the drawer.
    _switchQuestionModeCallback = page > 0 &&
            userType == UserType.teacher &&
            _viewSpan == Target.individual
        ? () => _switchToQuestionManagerMode(context)
        : null;
    setState(() {});
  }

  void _filterAnswers() async {
    final answerFilter = await showDialog<AnswerSortAndFilter>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return FilterAnswerDialog(currentFilter: _answerFilter);
      },
    );
    if (answerFilter == null) return;

    _answerFilter = answerFilter;
    setState(() {});
  }

  Future<void> _showConnectedToken() async {
    final studentId =
        Provider.of<Database>(context, listen: false).currentUser!.id;

    final token =
        await TeachingTokenHelpers.connectedToken(studentId: studentId);
    if (token == null) return await _connectToToken(forceYes: true);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connecté au code d\'inscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SelectableText(
                  token,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _connectToToken();
                },
                child: const Text('Connecter un nouveau code',
                    style: TextStyle(color: Colors.black))),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  bool _isConnectingToken = false;
  Future<void> _connectToToken({bool forceYes = false}) async {
    if (!forceYes) {
      final sure = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AreYouSureDialog(
            title: 'Se connecter à un nouveau code ?',
            canReadAloud: true,
            content:
                'Êtes-vous certain(e) de vouloir vous connecter à un nouveau code ?\n'
                'Ceci archivera vos discussions avec l\'enseignant·e actuelle.',
          );
        },
      );
      if (!mounted) return;
      if (sure != true) {
        final scaffold = ScaffoldMessenger.of(context);
        _showSnackbar(
            const Text('Génération du nouveau code annulée'), scaffold);
        return;
      }
    }

    final controller = TextEditingController();
    final isSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final enterCodeText =
            'Entrez ici le code d\'inscription fourni par votre enseignant·e';
        return AlertDialog(
          title: Text('Entrer le code d\'inscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: IconButton(
                        onPressed: () {
                          final textReader = TextReader();
                          textReader.readText(
                            enterCodeText,
                            hasFinishedCallback: () => textReader.stopReading(),
                          );
                        },
                        icon: const Icon(Icons.volume_up)),
                  ),
                  Text(enterCodeText),
                ],
              ),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Code d\'inscription',
                ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0, right: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Annuler')),
                      SizedBox(width: 20),
                      ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Valider')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    final token = controller.text;
    controller.dispose();

    if (isSuccess != true) {
      if (mounted) {
        final scaffold = ScaffoldMessenger.of(context);
        _showSnackbar(
            const Text('Génération du nouveau code annulée'), scaffold);
      }
      return;
    }

    final teacherId = await TeachingTokenHelpers.creatorIdOf(token: token);
    if (teacherId == null) {
      if (mounted) {
        final scaffold = ScaffoldMessenger.of(context);
        _showSnackbar(
            const Text('Aucun enseignant·e n\'est associé·e à ce code'),
            scaffold);
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isConnectingToken = true;
    });

    final database = Provider.of<Database>(context, listen: false);
    _currentToken = token;
    final studentId = database.currentUser!.id;

    await TeachingTokenHelpers.connectToToken(
        token: _currentToken!, studentId: studentId, teacherId: teacherId);
    await database.initializeAnswersDatabase(
        studentId: studentId, token: _currentToken!);

    if (!mounted) return;
    setState(() {
      _isConnectingToken = false;
    });
    await _showConnectedToken();
  }

  Future<void> onPageChangedRequest(int page) async {
    await _pageController.animateToPage(page + 1,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBackPressed() async {
    if (_currentPage == 0) {
      // Replacement is used to force the redraw of the Notifier.
      // If the redrawing is ever fixed, this can be replaced by a pop.
      RouteManager.instance.gotoStudentsPage(context);
    }
    await onPageChangedRequest(-1);
  }

  void _switchToQuestionManagerMode(BuildContext context) {
    final userType = Provider.of<Database>(context, listen: false).userType;
    if (userType == UserType.student) return;
    if (_pageMode == PageMode.fixView) return;

    _pageMode =
        _pageMode == PageMode.edit ? PageMode.editableView : PageMode.edit;
    setState(() {});
  }

  PreferredSizeWidget _setAppBar() {
    final currentUser =
        Provider.of<Database>(context, listen: false).currentUser;
    final currentTheme = Theme.of(context).textTheme.titleLarge!;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final userType = Provider.of<Database>(context, listen: false).userType;

    return ResponsiveService.appBarOf(
      context,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingContainer(
            onReady: (context) =>
                onboardingContexts['q_and_a_app_bar_title'] = context,
            child: Text(_student?.toString() ??
                (_pageMode == PageMode.fixView
                    ? 'Résumé des réponses'
                    : 'Gestion des questions')),
          ),
          if (userType == UserType.student)
            Text(
                _currentPage == 0
                    ? "Mon stage en images"
                    : Section.name(_currentPage - 1),
                style:
                    currentTheme.copyWith(fontSize: 15, color: onPrimaryColor)),
          if (userType == UserType.teacher && _student != null)
            Text(
              currentUser?.studentNotes[_student!.id] ?? '',
              style: currentTheme.copyWith(fontSize: 15, color: onPrimaryColor),
            ),
        ],
      ),
      leading:
          _currentPage != 0 || _student != null && userType == UserType.teacher
              ? BackButton(onPressed: _onBackPressed)
              : null,
      actions: _currentPage != 0 && userType == UserType.teacher
          ? [
              if (_viewSpan == Target.individual)
                IconButton(
                  onPressed: _switchQuestionModeCallback,
                  icon: Icon(_pageMode == PageMode.edit
                      ? Icons.edit_off
                      : Icons.edit_rounded),
                  iconSize: 30,
                ),
              if (_viewSpan == Target.all && _pageMode == PageMode.fixView)
                IconButton(
                  onPressed: _filterAnswers,
                  icon: const Icon(Icons.filter_alt),
                  iconSize: 30,
                ),
              const SizedBox(width: 15),
            ]
          : [
              IconButton(
                onPressed: _showConnectedToken,
                icon: const Icon(Icons.qr_code_2),
                iconSize: 35,
                color: Colors.black,
              ),
              const SizedBox(width: 15),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<Database>(context, listen: false);
    final userId = database.currentUser?.id;
    if (userId == null || _isConnectingToken) {
      return ResponsiveService.scaffoldOf(
        context,
        appBar: _setAppBar(),
        body: Center(
            child: Text(userId == null
                ? 'Utilisateur non connecté'
                : 'Connexion au code...')),
        smallDrawer: MainDrawer.small,
        mediumDrawer: MainDrawer.medium,
        largeDrawer: MainDrawer.large,
      );
    }

    return ResponsiveService.scaffoldOf(
      context,
      appBar: _setAppBar(),
      body: _currentToken == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  'Aucun code actif trouvé\n'
                  'Cliquez sur le code QR en haut à droite pour vous connecter à un·e enseignant·e.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                MetierAppBar(
                  selected: _currentPage - 1,
                  onPageChanged: onPageChangedRequest,
                  studentId: _student?.id,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) => onPageChanged(context, value),
                    children: [
                      MainMetierPage(
                          student: _student,
                          onPageChanged: onPageChangedRequest),
                      QuestionAndAnswerPage(
                        0,
                        studentId: _student?.id,
                        viewSpan: _viewSpan,
                        pageMode: _pageMode,
                        answerFilterMode: _answerFilter,
                      ),
                      QuestionAndAnswerPage(
                        1,
                        studentId: _student?.id,
                        viewSpan: _viewSpan,
                        pageMode: _pageMode,
                        answerFilterMode: _answerFilter,
                      ),
                      QuestionAndAnswerPage(
                        2,
                        studentId: _student?.id,
                        viewSpan: _viewSpan,
                        pageMode: _pageMode,
                        answerFilterMode: _answerFilter,
                      ),
                      QuestionAndAnswerPage(
                        3,
                        studentId: _student?.id,
                        viewSpan: _viewSpan,
                        pageMode: _pageMode,
                        answerFilterMode: _answerFilter,
                      ),
                      QuestionAndAnswerPage(
                        4,
                        studentId: _student?.id,
                        viewSpan: _viewSpan,
                        pageMode: _pageMode,
                        answerFilterMode: _answerFilter,
                      ),
                      QuestionAndAnswerPage(
                        5,
                        studentId: _student?.id,
                        viewSpan: _viewSpan,
                        pageMode: _pageMode,
                        answerFilterMode: _answerFilter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
    );
  }
}

void _showSnackbar(Widget content, ScaffoldMessengerState scaffold) {
  scaffold.showSnackBar(
    SnackBar(
        content: content,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: scaffold.hideCurrentSnackBar,
        )),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
