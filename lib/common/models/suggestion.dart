import 'package:enhanced_containers_foundation/item_serializable.dart';

class Suggestion extends ItemSerializable {
  final String userId;
  final String content;
  final DateTime submittedAt;

  Suggestion({
    super.id,
    required this.userId,
    required this.content,
    required this.submittedAt,
  });

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'userId': userId,
        'content': content,
        'submittedAt': submittedAt.toIso8601String(),
      };

  Suggestion.fromSerialized(Map<String, dynamic> super.map)
      : userId = map['userId'],
        content = map['content'],
        submittedAt = DateTime.parse(map['submittedAt']),
        super.fromSerialized();
}
