import 'package:defi_photo/crcrme_enhanced_containers/lib/item_serializable.dart';

class Company extends ItemSerializable {
  Company({required this.name, String? id}) : super(id: id);
  Company copyWith({String? name, String? id}) {
    name ??= this.name;
    id ??= this.id;
    return Company(name: name, id: id);
  }

  Company.fromSerialized(map)
      : name = map['name'] ?? 'No name',
        super.fromSerialized(map);

  final String name;

  @override
  String toString() => name.toString();

  @override
  Company deserializeItem(map) {
    return Company.fromSerialized(map);
  }

  @override
  Map<String, dynamic> serializedMap() {
    return {'name': name};
  }
}
