class GroupMemberModel {
  final String userId;
  final String fullName;

  GroupMemberModel({required this.userId, required this.fullName});

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
    );
  }
}
