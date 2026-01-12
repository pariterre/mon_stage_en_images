import 'package:ezlogin/ezlogin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mon_stage_en_images/common/misc/database_helper.dart';
import 'package:mon_stage_en_images/common/models/database.dart';

final _isMigrating = [];

class User extends EzloginUser {
  // Constructors and (de)serializer
  User({
    required this.firstName,
    required this.lastName,
    required super.email,
    required this.supervisedBy,
    required this.supervising,
    required super.mustChangePassword,
    required this.studentNotes,
    required this.termsAndServicesAccepted,
    required this.creationDate,
    super.id,
  });

  User.fromSerialized(Map? map)
      : firstName = map?['firstName'],
        lastName = map?['lastName'],
        supervisedBy = map?['supervisedBy'],
        supervising =
            (map?['supervising'] as Map?)?.map((k, v) => MapEntry(k, v)) ?? {},
        studentNotes = (map?['studentNotes'] as Map?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
        termsAndServicesAccepted = map?['termsAndServicesAccepted'] ?? false,
        creationDate =
            DateTime.parse(map?['creationDate'] ?? defaultCreationDate),
        super.fromSerialized(map) {
    if ((map?.containsKey('userType') ?? false)) {
      // TODO Add onError
      _migrateFromVersionWithUserTypes();
    }
  }

  @override
  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? supervisedBy,
    Map<String, bool>? supervising,
    bool? mustChangePassword,
    String? id,
    Map<String, String>? studentNotes,
    bool? termsAndServicesAccepted,
    DateTime? creationDate,
  }) {
    return User(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      supervisedBy: supervisedBy ?? this.supervisedBy,
      supervising: supervising ?? this.supervising,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      id: id ?? this.id,
      studentNotes: studentNotes ?? this.studentNotes,
      termsAndServicesAccepted:
          termsAndServicesAccepted ?? this.termsAndServicesAccepted,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'firstName': firstName,
      'lastName': lastName,
      'supervisedBy': supervisedBy,
      'supervising': supervising,
      'studentNotes': studentNotes,
      'termsAndServicesAccepted': termsAndServicesAccepted,
      'creationDate': creationDate.toIso8601String(),
    });

  @override
  User deserializeItem(map) {
    return User.fromSerialized(map);
  }

  // Attributes and methods
  final String firstName;
  final String lastName;
  final String supervisedBy;
  final Map<String, bool> supervising;
  final Map<String, String> studentNotes;
  final bool termsAndServicesAccepted;
  final DateTime creationDate;

  bool get isActive => creationDate.isAfter(isActiveLimitDate);
  bool get isNotActive => !isActive;

  @override
  String toString() => '$firstName $lastName';

  Future<void> _migrateFromVersionWithUserTypes() async {
    final currentId = FirebaseAuth.instance.currentUser!.uid;
    if (_isMigrating.contains(currentId)) return;
    _isMigrating.add(id);

    final userType = (await FirebaseDatabase.instance
            .ref('users')
            .child('$currentId/userType')
            .get())
        .value as int?;
    if (userType != 1) return;

    // Migrate the company names to student notes
    final supervisingData = (await FirebaseDatabase.instance
            .ref('users')
            .child('$currentId/supervising')
            .get())
        .value as Map?;

    for (final studentId in supervisingData?.keys ?? <String>[]) {
      final data = await FirebaseDatabase.instance
          .ref('users')
          .child('$studentId/companyNames')
          .get();
      if (data.value != null) studentNotes[studentId] = data.value.toString();
      await FirebaseDatabase.instance
          .ref('users')
          .child('$studentId/companyNames')
          .remove();
    }
    await FirebaseDatabase.instance
        .ref('users')
        .child('${FirebaseAuth.instance.currentUser!.uid}/studentNotes')
        .set(studentNotes);

    _isMigrating.remove(currentId);
  }
}
