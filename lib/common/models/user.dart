import 'package:mon_stage_en_images/common/misc/database_helper.dart';
import 'package:mon_stage_en_images/common/providers/database.dart';

class User extends EzloginUser {
  // Constructors and (de)serializer
  User({
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required super.email,
    required this.studentNotes,
    required this.creationDate,
    required this.termsAndServicesAccepted,
    required this.irsstPageSeen,
    required this.hasSeenTeacherOnboarding,
    required this.hasSeenStudentOnboarding,
    super.id,
  }) : super(mustChangePassword: false);

  User.limitedUser({
    super.id,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  })  : studentNotes = {},
        creationDate = DateTime.now(),
        termsAndServicesAccepted = false,
        irsstPageSeen = false,
        hasSeenTeacherOnboarding = false,
        hasSeenStudentOnboarding = false,
        super(email: '', mustChangePassword: false);

  User.fromSerialized(super.map)
      : firstName = map?['firstName'],
        lastName = map?['lastName'],
        avatar = map?['avatar'],
        studentNotes = (map?['studentNotes'] as Map?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
        creationDate =
            DateTime.parse(map?['creationDate'] ?? defaultCreationDate),
        termsAndServicesAccepted = map?['termsAndServicesAccepted'] ?? false,
        irsstPageSeen = map?['irsstPageSeen'] ?? false,
        hasSeenTeacherOnboarding = map?['hasSeenTeacherOnboarding'] ?? false,
        hasSeenStudentOnboarding = map?['hasSeenStudentOnboarding'] ?? false,
        super.fromSerialized();

  @override
  User copyWith({
    String? firstName,
    String? lastName,
    String? avatar,
    String? email,
    bool? mustChangePassword,
    String? id,
    DateTime? creationDate,
    Map<String, String>? studentNotes,
    bool? termsAndServicesAccepted,
    bool? irsstPageSeen,
    bool? hasSeenTeacherOnboarding,
    bool? hasSeenStudentOnboarding,
  }) {
    if (mustChangePassword != null) {
      throw UnimplementedError(
          'User model does not support changing mustChangePassword');
    }

    return User(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      id: id ?? this.id,
      creationDate: creationDate ?? this.creationDate,
      studentNotes: studentNotes ?? this.studentNotes,
      termsAndServicesAccepted:
          termsAndServicesAccepted ?? this.termsAndServicesAccepted,
      irsstPageSeen: irsstPageSeen ?? this.irsstPageSeen,
      hasSeenTeacherOnboarding:
          hasSeenTeacherOnboarding ?? this.hasSeenTeacherOnboarding,
      hasSeenStudentOnboarding:
          hasSeenStudentOnboarding ?? this.hasSeenStudentOnboarding,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatar,
      'creationDate': creationDate.toIso8601String(),
      'studentNotes': studentNotes,
      'termsAndServicesAccepted': termsAndServicesAccepted,
      'irsstPageSeen': irsstPageSeen,
      'hasSeenTeacherOnboarding': hasSeenTeacherOnboarding,
      'hasSeenStudentOnboarding': hasSeenStudentOnboarding,
    });

  @override
  User deserializeItem(map) {
    return User.fromSerialized(map);
  }

  // Attributes and methods
  final String firstName;
  final String lastName;
  final String avatar;
  final Map<String, String> studentNotes;
  final DateTime creationDate;
  final bool termsAndServicesAccepted;
  final bool irsstPageSeen;
  final bool hasSeenTeacherOnboarding;
  final bool hasSeenStudentOnboarding;

  @override
  String toString() => '$firstName $lastName';
}
