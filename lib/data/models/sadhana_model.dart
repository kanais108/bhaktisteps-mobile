class SadhanaModel {
  final String id;
  final String userId;
  final DateTime entryDate;
  final int japaRounds;
  final bool mangalaArati;
  final bool tulasiPuja;
  final bool guruPuja;
  final bool bhagavatamClass;
  final int readingMinutes;
  final int serviceMinutes;
  final String? sleptAt;
  final String? wokeUpAt;
  final String? notes;

  SadhanaModel({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.japaRounds,
    required this.mangalaArati,
    required this.tulasiPuja,
    required this.guruPuja,
    required this.bhagavatamClass,
    required this.readingMinutes,
    required this.serviceMinutes,
    this.sleptAt,
    this.wokeUpAt,
    this.notes,
  });

  factory SadhanaModel.fromJson(Map<String, dynamic> json) {
    return SadhanaModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      entryDate: DateTime.parse(json['entryDate'] as String),
      japaRounds: json['japaRounds'] as int,
      mangalaArati: json['mangalaArati'] as bool,
      tulasiPuja: json['tulasiPuja'] as bool,
      guruPuja: json['guruPuja'] as bool,
      bhagavatamClass: json['bhagavatamClass'] as bool,
      readingMinutes: json['readingMinutes'] as int,
      serviceMinutes: json['serviceMinutes'] as int,
      sleptAt: json['sleptAt'] as String?,
      wokeUpAt: json['wokeUpAt'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
