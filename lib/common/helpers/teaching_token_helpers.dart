import 'package:firebase_database/firebase_database.dart';
import 'package:mon_stage_en_images/common/models/database.dart';

class TeachingTokenHelpers {
  static Future<String> registerToken(String teacherId, String token) async {
    await Database.root
        .child('tokens')
        .child(token)
        .child('metadata')
        .set({'createdBy': teacherId});
    // TODO set other teachersId's token to isActive false

    await Database.root
        .child('users')
        .child(teacherId)
        .child('tokens')
        .child('created')
        .set({
      token: {'createdAt': ServerValue.timestamp, 'isActive': true}
    });

    return token;
  }

  static Future<void> unregisterToken(String teacherId, String token) async {
    // TODO check this
    await Database.root
        .child('users')
        .child(teacherId)
        .child('tokens')
        .child('created')
        .child(token)
        .child('isActive')
        .set(false);
  }

  static Future<void> connectToToken(
      String studentId, String teacherId, String token) async {
    await Database.root
        .child('tokens')
        .child(token)
        .child('connectedUsers')
        .update({studentId: true});

    await Database.root
        .child('users')
        .child(studentId)
        .child('tokens')
        .child('connected')
        .set({token: true});

    await Database.root
        .child('users')
        .child(studentId)
        .child('tokens')
        .child('userWithExtendedPermissions')
        .set({teacherId: true});
  }

  /// Disconnect a student from a token
  static Future<void> disconnectFromToken(
      String studentId, String token) async {
    // TODO Check this
    await Database.root
        .child('tokens')
        .child(token)
        .child('connectedUsers')
        .child(studentId)
        .remove();

    await Database.root
        .child('users')
        .child(studentId)
        .child('tokens')
        .child('connected')
        .child(token)
        .remove();

    await Database.root
        .child('users')
        .child(studentId)
        .child('tokens')
        .child('userWithExtendedPermissions')
        .remove();
  }

  ///
  /// Generate a 6-character token that is not already in the database
  static Future<String> generateUniqueToken() async {
    final existingTokens = await _existingTokens();

    const chars = 'ABCDEFGHJKMNPQRSTUVXY3456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    String token;
    do {
      token = List.generate(6, (index) {
        final indexChar = (rand + index * 37) % chars.length;
        return chars[indexChar];
      }).join();
    } while (existingTokens.contains(token));

    return token;
  }

  static Future<Set<String>> _existingTokens() async {
    final data = await Database.root.child('tokens').get();
    return (data.value as Map?)?.keys.cast<String>().toSet() ?? {};
  }

  static Future<String?> connectedToken({required String studentId}) async {
    final tokensSnapshot = Database.root
        .child('users')
        .child(studentId)
        .child('tokens')
        .child('connected');
    final tokens = ((await tokensSnapshot.get()).value as Map?);
    if (tokens == null || tokens.isEmpty) return null;

    return tokens.keys.first;
  }

  static Future<String> creatorIdOf({required String token}) async {
    final snapshot = (await Database.root
        .child('tokens')
        .child(token)
        .child('metadata')
        .child('createdBy')
        .get());
    return snapshot.value as String;
  }

  static Future<Iterable<String>> userIdsConnectedTo(
      {required String token}) async {
    final snapshot = await Database.root
        .child('tokens')
        .child(token)
        .child('connectedUsers')
        .get();
    return (snapshot.value as Map?)?.keys.cast<String>() ?? [];
  }

  static Future<Iterable<String>> createdTokens(
      {required String userId, bool activeOnly = true}) async {
    final snapshot = await Database.root
        .child('users')
        .child(userId)
        .child('tokens')
        .child('created')
        .get();

    final tokens = (snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
    if (activeOnly) {
      return tokens.entries
          .where((entry) => (entry.value as Map?)?['isActive'] == true)
          .map((entry) => entry.key);
    } else {
      return tokens.keys;
    }
  }
}
