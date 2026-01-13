import 'package:mon_stage_en_images/common/misc/database_helper.dart';
import 'package:mon_stage_en_images/common/models/database.dart';

class User extends EzloginUser {
  // Constructors and (de)serializer
  User({
    required this.firstName,
    required this.lastName,
    required super.email,
    required super.mustChangePassword,
    required this.studentNotes,
    required this.termsAndServicesAccepted,
    required this.creationDate,
    required this.connectedTokens,
    super.id,
  });

  User.fromSerialized(super.map)
      : firstName = map?['firstName'],
        lastName = map?['lastName'],
        studentNotes = (map?['studentNotes'] as Map?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
        termsAndServicesAccepted = map?['termsAndServicesAccepted'] ?? false,
        creationDate =
            DateTime.parse(map?['creationDate'] ?? defaultCreationDate),
        connectedTokens = (map?['connectedTokens'] as Map?)
                ?.cast<String, dynamic>()
                .keys
                .toList() ??
            [],
        super.fromSerialized();

  @override
  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    bool? mustChangePassword,
    String? id,
    Map<String, String>? studentNotes,
    bool? termsAndServicesAccepted,
    DateTime? creationDate,
    Map<String, int>? teachingTokens,
    List<String>? connectedTokens,
  }) {
    return User(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      id: id ?? this.id,
      studentNotes: studentNotes ?? this.studentNotes,
      termsAndServicesAccepted:
          termsAndServicesAccepted ?? this.termsAndServicesAccepted,
      creationDate: creationDate ?? this.creationDate,
      connectedTokens: connectedTokens ?? this.connectedTokens,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'firstName': firstName,
      'lastName': lastName,
      'studentNotes': studentNotes,
      'termsAndServicesAccepted': termsAndServicesAccepted,
      'creationDate': creationDate.toIso8601String(),
      'connectedTokens':
          connectedTokens.asMap().map((k, v) => MapEntry(v, true)),
    });

  @override
  User deserializeItem(map) {
    return User.fromSerialized(map);
  }

  // Attributes and methods
  final String firstName;
  final String lastName;
  final Map<String, String> studentNotes;
  final bool termsAndServicesAccepted;
  final DateTime creationDate;
  final List<String> connectedTokens; // Tokens the user is connected to

  bool get isActive => creationDate.isAfter(isActiveLimitDate);
  bool get isNotActive => !isActive;

  @override
  String toString() => '$firstName $lastName';
}
