class EventModel {
  final String id;
  final String templeId;
  final String? groupId;
  final String category;
  final String title;
  final String? description;
  final String eventMode;
  final String? locationName;
  final String? posterImageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  final String attendanceMode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.templeId,
    this.groupId,
    required this.category,
    required this.title,
    this.description,
    required this.eventMode,
    this.locationName,
    this.posterImageUrl,
    required this.startsAt,
    required this.endsAt,
    required this.attendanceMode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      templeId: json['templeId'] as String,
      groupId: json['groupId'] as String?,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventMode: json['eventMode'] as String,
      locationName: json['locationName'] as String?,
      posterImageUrl: json['posterImageUrl'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      attendanceMode: json['attendanceMode'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
