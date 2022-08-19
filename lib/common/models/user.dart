import 'package:defi_photo/crcrme_enhanced_containers/lib/item_serializable.dart';

import '../misc/database_helper.dart';

class User extends ItemSerializable {
  // Constructors and (de)serializer
  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.addedBy,
    required this.isStudent,
    required this.shouldChangePassword,
    this.studentId,
  }) : super(id: emailToPath(email));
  User.fromSerialized(map)
      : firstName = map['firstName'],
        lastName = map['lastName'],
        email = map['email'],
        addedBy = map['addedBy'],
        isStudent = map['isStudent'],
        shouldChangePassword = map[shouldChangePasswordNameField],
        studentId = map['studentId'],
        super.fromSerialized(map);

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'addedBy': addedBy,
      'isStudent': isStudent,
      shouldChangePasswordNameField: shouldChangePassword,
      'studentId': studentId,
    };
  }

  @override
  User deserializeItem(map) {
    return User.fromSerialized(map);
  }

  // Attributes and methods
  final String firstName;
  final String lastName;
  final String email;
  final String addedBy;
  final bool isStudent;
  final bool shouldChangePassword;

  /// If [shouldChangePassword] ever change, the nameField should be updated
  static const String shouldChangePasswordNameField = 'shouldChangePassword';
  final String? studentId;

  @override
  String toString() {
    return '$email added by $addedBy';
  }
}
