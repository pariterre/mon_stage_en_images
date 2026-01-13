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
    required this.connexionTokens,
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
        connexionTokens = (map?['connexionTokens'] as Map?)
                ?.map((k, v) => MapEntry(int.parse(k), v.toString())) ??
            {},
        connectedTokens =
            (map?['connectedTokens'] as Map?)?.map((k, v) => MapEntry(k, v)) ??
                {},
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
    Map<int, String>? connexionTokens,
    Map<String, bool>? connectedTokens,
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
      connexionTokens: connexionTokens ?? this.connexionTokens,
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
      'connexionTokens': connexionTokens,
      'connectedTokens': connectedTokens,
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
  final Map<int, String> connexionTokens; // Tokens the user created
  final Map<String, bool> connectedTokens; // Tokens the user is connected to

  bool get isActive => creationDate.isAfter(isActiveLimitDate);
  bool get isNotActive => !isActive;

  @override
  String toString() => '$firstName $lastName';
}
