class GroupModel {
  final String id;
  final String name;

  GroupModel({required this.id, required this.name});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(id: json['id'], name: json['name']);
  }
}
