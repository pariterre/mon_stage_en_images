import 'package:firebase_database/firebase_database.dart';
import 'package:mon_stage_en_images/common/models/database.dart';

class TeachingTokenHelpers {
  static Future<String> registerNewTeachingToken(String teacherId) async {
    final token = await TeachingTokenHelpers._generateUniqueTeachingToken();
    await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens')
        .child('collection')
        .child(token)
        .child('metadata')
        .set({'createdBy': teacherId});
    // TODO set other teachersId's token to isActive false

    await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens')
        .child('status')
        .child(teacherId)
        .child('created')
        .set({
      token: {'createdAt': ServerValue.timestamp, 'isActive': true}
    });

    return token;
  }

  static Future<void> connectToTeachingToken(
      String studentId, String teacherId, String token) async {
    await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens')
        .child('collection')
        .child(token)
        .child('connectedUsers')
        .update({studentId: true});

    await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens')
        .child('status')
        .child(studentId)
        .child('connected')
        .set({
      token: {'isActive': true}
    });

    await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens')
        .child('status')
        .child(studentId)
        .child('extendedPermissionsUsers')
        .set({teacherId: true});

    // TODO set other studentsId's token to false (disconnected, but previously connected)
  }

  ///
  /// Generate a 6-character token that is not already in the database
  static Future<String> _generateUniqueTeachingToken() async {
    final existingTeachingTokens = await _existingTeachingTokens();

    const chars = 'ABCDEFGHJKMNPQRSTUVXY3456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    String token;
    do {
      token = List.generate(6, (index) {
        final indexChar = (rand + index * 37) % chars.length;
        return chars[indexChar];
      }).join();
    } while (existingTeachingTokens.contains(token));

    return token;
  }

  static Future<Set<String>> _existingTeachingTokens() async {
    final data = await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens/collection')
        .get();
    return (data.value as Map?)?.keys.cast<String>().toSet() ?? {};
  }

  static Future<Iterable<String>> connectedUserIdsTo(
      {required String token}) async {
    final connectedUsersSnapshot = await FirebaseDatabase.instance
        .ref(
            '${Database.currentDatabaseVersion}/tokens/collection/$token/connectedUsers')
        .get();
    return (connectedUsersSnapshot.value as Map?)?.keys.cast<String>() ?? [];
  }

  static Future<Iterable<String>> createdTokens(
      {required String userId, bool activeOnly = true}) async {
    final statusSnapshot = await FirebaseDatabase.instance
        .ref('${Database.currentDatabaseVersion}/tokens/status/$userId/created')
        .get();

    final statusData =
        (statusSnapshot.value as Map?)?.cast<String, dynamic>() ?? {};
    if (activeOnly) {
      return statusData.entries
          .where((entry) => (entry.value as Map?)?['isActive'] == true)
          .map((entry) => entry.key);
    } else {
      return statusData.keys;
    }
  }
}
