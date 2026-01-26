import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/helpers/responsive_service.dart';
import 'package:mon_stage_en_images/common/models/suggestion.dart';
import 'package:mon_stage_en_images/common/providers/database.dart';
import 'package:mon_stage_en_images/common/widgets/are_you_sure_dialog.dart';
import 'package:provider/provider.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  static Future<void> showSuggestionPage(BuildContext context) async {
    final suggestions = await showDialog<String>(
        context: context, builder: (context) => const SuggestionsPage());
    if (suggestions == null) return;

    if (!context.mounted) return;
    final database = Provider.of<Database>(context, listen: false);
    await database.sendSuggestion(
        suggestion: Suggestion(
            userId: database.currentUser!.id,
            content: suggestions,
            submittedAt: DateTime.now()));
  }

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSubmitted() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_textController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AreYouSureDialog(
      title: 'Suggestions',
      content: 'Vos suggestions nous aident à améliorer l\'application.\n'
          'N\'hésitez pas à nous faire part de vos idées !',
      extraContent: Column(
        children: [
          SizedBox(height: 12, width: ResponsiveService.smallScreenWidth),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Entrez vos suggestions ici',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une suggestion';
                }
                if (value.length < 10) {
                  return 'La suggestion doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
          ),
        ],
      ),
      onCancelled: () => Navigator.of(context).pop(),
      onConfirmed: _onSubmitted,
    );
  }
}
