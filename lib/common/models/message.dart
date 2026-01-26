import 'package:enhanced_containers/enhanced_containers.dart';

class Message extends ItemSerializableWithCreationTime {
  // Constructors and (de)serializer
  Message({
    required this.studentId,
    required this.text,
    this.isPhotoUrl = false,
    super.id,
    super.creationTimeStamp,
    required this.creatorId,
    required this.isDeleted,
  });
  Message.fromSerialized(super.map)
      : studentId = map?['studentId'],
        text = map?['text'],
        isPhotoUrl = map?['isPhotoUrl'],
        creatorId = map?['creatorId'],
        isDeleted = map?['isDeleted'] ?? false,
        super.fromSerialized();

  Message deserializeItem(Map? map) => Message.fromSerialized(map);

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'studentId': studentId,
      'text': text,
      'isPhotoUrl': isPhotoUrl,
      'creatorId': creatorId,
      'isDeleted': isDeleted,
    };
  }

  Message copyWith({
    String? studentId,
    String? text,
    bool? isPhotoUrl,
    String? creatorId,
    bool? isDeleted,
  }) {
    if (isDeleted == true) {
      if (text != null) {
        throw Exception('A deleted message cannot have a text.');
      }
      text = isPhotoUrl == true ? '[Photo supprimée]' : '[Message supprimé]';
      isPhotoUrl = false;
    }

    return Message(
      studentId: studentId ?? this.studentId,
      text: text ?? this.text,
      isPhotoUrl: isPhotoUrl ?? this.isPhotoUrl,
      id: id,
      creationTimeStamp: creationTimeStamp,
      creatorId: creatorId ?? this.creatorId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Attributes and methods
  final String studentId;
  final String text;
  final bool isPhotoUrl;
  final String creatorId;
  final bool isDeleted;
}
