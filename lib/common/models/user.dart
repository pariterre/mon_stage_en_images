import 'package:enhanced_containers_foundation/item_serializable.dart';
import 'package:ezlogin/ezlogin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mon_stage_en_images/common/misc/database_helper.dart';
import 'package:mon_stage_en_images/common/models/database.dart';

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

  User.fromSerialized(super.map)
      : firstName = map?['firstName'],
        lastName = map?['lastName'],
        supervisedBy = map?['supervisedBy'],
        supervising =
            (map?['supervising'] as Map?)?.map((k, v) => MapEntry(k, v)) ?? {},
        studentNotes =
            StudentNotes.fromSerialized(map?['studentNotes'] as Map?),
        termsAndServicesAccepted = map?['termsAndServicesAccepted'] ?? false,
        creationDate =
            DateTime.parse(map?['creationDate'] ?? defaultCreationDate),
        super.fromSerialized();

  @override
  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? supervisedBy,
    Map<String, bool>? supervising,
    bool? mustChangePassword,
    String? id,
    StudentNotes? studentNotes,
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
      'studentNotes': studentNotes.serialize(),
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
  final StudentNotes studentNotes;
  final bool termsAndServicesAccepted;
  final DateTime creationDate;

  bool get isActive => creationDate.isAfter(isActiveLimitDate);
  bool get isNotActive => !isActive;

  @override
  String toString() => '$firstName $lastName';
}

class StudentNotes extends ItemSerializable {
  final Map<String, String> _studentNotes;

  StudentNotes._(this._studentNotes);
  StudentNotes.empty() : _studentNotes = {};

  @override
  Map<String, dynamic> serializedMap() => _studentNotes;

  static StudentNotes fromSerialized(Map? map) {
    return StudentNotes._((map ?? {}).map((k, v) => MapEntry(k, v.toString())));
  }

  String? operator [](String? studentId) {
    if (studentId == null) return null;

    // Historically, studentNotes was companyNames stored in the student object.
    // Now, it is in the teacher's object as a map of studentId to notes. The
    // following line ensures backward compatibility (and migration) for old users.
    if (_studentNotes[studentId] == null) _updateDatabaseCompanyName(studentId);

    return _studentNotes[studentId];
  }

  void operator []=(String studentId, String note) =>
      _studentNotes[studentId] = note;

  Future<void> _updateDatabaseCompanyName(String studentId) async {
    final data = await FirebaseDatabase.instance
        .ref('users')
        .child('$studentId/companyNames')
        .get();

    if (data.value != null) _studentNotes[studentId] = data.value.toString();

    await FirebaseDatabase.instance
        .ref('users')
        .child('${FirebaseAuth.instance.currentUser!.uid}/studentNotes')
        .set(serialize());

    await FirebaseDatabase.instance
        .ref('users')
        .child('$studentId/companyNames')
        .remove();
  }
}
