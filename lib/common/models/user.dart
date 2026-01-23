import 'dart:math';

import 'package:mon_stage_en_images/common/misc/database_helper.dart';
import 'package:mon_stage_en_images/common/models/database.dart';

class User extends EzloginUser {
  static String get randomEmoji {
    final defaultEmojis = [
      // Faces
      '🐶', '🐺', '🐱', '🦁', '🐯', '🐴', '🦄', '🐮', '🐷', '🐽', '🐸', '🐵',
      '🙈', '🙉', '🙊',

      // Pets & farm
      '🐹', '🐰', '🦊', '🐻', '🐼', '🐻‍❄️', '🐨', '🐮', '🐔', '🐤', '🐥', '🐣',
      '🐧', '🦆', '🦅', '🦉', '🦇',

      // Wild animals
      '🐗', '🐴', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🦒',
      '🐪', '🐫', '🦙', '🦌', '🦬',

      // Sea life
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨',
      '🐟', '🐠', '🐡', '🦈', '🐬', '🐳', '🐋', '🦭', '🐙', '🦑', '🦀', '🦞',
      '🦐',

      // Reptiles & insects
      '🐍', '🦎', '🐢', '🐊', '🦖', '🦕',
      '🐝', '🐞', '🦋', '🐛', '🪲', '🪳', '🕷️', '🦂',

      // More birds
      '🦃', '🦚', '🦜', '🦢', '🦩', '🕊️', '🐦',

      // Extras
      '🦘', '🦥', '🦦', '🦨', '🦡', '🐿️', '🦔',
    ];
    return defaultEmojis[Random().nextInt(defaultEmojis.length)];
  }

  // Constructors and (de)serializer
  User({
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required super.email,
    required this.studentNotes,
    required this.termsAndServicesAccepted,
    required this.creationDate,
    super.id,
  }) : super(mustChangePassword: false);

  User.fromSerialized(super.map)
      : firstName = map?['firstName'],
        lastName = map?['lastName'],
        avatar = map?['avatar'] ?? User.randomEmoji,
        studentNotes = (map?['studentNotes'] as Map?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
        termsAndServicesAccepted = map?['termsAndServicesAccepted'] ?? false,
        creationDate =
            DateTime.parse(map?['creationDate'] ?? defaultCreationDate),
        super.fromSerialized();

  @override
  User copyWith({
    String? firstName,
    String? lastName,
    String? avatar,
    String? email,
    bool? mustChangePassword,
    String? id,
    Map<String, String>? studentNotes,
    bool? termsAndServicesAccepted,
    DateTime? creationDate,
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
      'avatar': avatar,
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
  final String avatar;
  final Map<String, String> studentNotes;
  final bool termsAndServicesAccepted;
  final DateTime creationDate;

  @override
  String toString() => '$firstName $lastName';
}
