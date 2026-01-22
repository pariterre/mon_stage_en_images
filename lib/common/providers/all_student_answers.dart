import 'package:enhanced_containers/enhanced_containers.dart';
import 'package:mon_stage_en_images/common/models/answer.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:mon_stage_en_images/common/providers/all_answers.dart';

class AllStudentAnswers extends FirebaseListProvided<Answer>
    implements AllAnswers {
  int get count => length;
  static const String dataName = 'answers';
  User? studentUser;

  AllStudentAnswers() : super(pathToData: dataName);

  @override
  Future<void> initializeFetchingData(
      {String? pathToData, User? studentUser}) async {
    if (pathToData == null) {
      throw 'You must set pathToData for initializing the answers database for students';
    }
    if (studentUser == null) {
      throw 'You must set studentUser for initializing the answers database for students';
    }
    this.pathToData = pathToData;
    this.studentUser = studentUser;
    await super.initializeFetchingData();
  }

  @override
  Future<void> stopFetchingData() async {
    await super.stopFetchingData();
    studentUser = null;
    pathToData = '';
  }

  @override
  Answer deserializeItem(data) {
    return Answer.fromSerialized(data);
  }

  @override
  void add(Answer item, {bool notify = true}) =>
      throw 'Use the "addAnswers" or "removeQuestion" methods instead';

  @override
  Future<void> replace(Answer item, {bool notify = true}) =>
      throw 'Use the "addAnswers" of "removeQuestion" methods instead';

  @override
  Future<void> addAnswers(Iterable<Answer> answers,
      {bool notify = true}) async {
    for (final answer in answers) {
      await super.replace(answer, notify: notify);
    }
    firebaseInstance.ref(pathToData).child('id').set(studentUser!.id);

    if (notify) notifyListeners();
  }

  @override
  void modifyAnswer(Answer answer, {bool notify = true}) =>
      addAnswers([answer], notify: notify);

  @override
  Iterable<Answer> filter({
    Iterable<String>? questionIds,
    Iterable<String>? studentIds,
    bool? isActive,
    bool? isAnswered,
    bool? hasAnswer,
  }) {
    if (studentIds?.length != 1 && studentIds!.toList()[0] != studentUser?.id) {
      throw 'You can only filter by the current student id in a student database';
    }
    return where((q) =>
        (questionIds == null || questionIds.contains(q.questionId)) &&
        (isActive == null || q.isActive == isActive) &&
        (isAnswered == null || q.isAnswered == isAnswered) &&
        (hasAnswer == null || q.hasAnswer == hasAnswer));
  }
}
