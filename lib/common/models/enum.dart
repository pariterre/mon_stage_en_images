class TypeException implements Exception {
  TypeException(this.message);

  final String message;
}

enum Target {
  none,
  individual,
  all,
}

enum ActionRequired {
  none,
  fromStudent,
  fromTeacher,
}

enum UserType {
  none,
  teacher,
  student;

  String serialize() {
    return switch (this) {
      UserType.none => 'none',
      UserType.teacher => 'teacher',
      UserType.student => 'student',
    };
  }

  static UserType deserialize(String? value) {
    return switch (value) {
      'teacher' => UserType.teacher,
      'student' => UserType.student,
      _ => UserType.none,
    };
  }
}

enum PageMode {
  fixView,
  editableView,
  edit,
}
