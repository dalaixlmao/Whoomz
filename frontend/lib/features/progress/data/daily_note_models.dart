class DailyNoteResponse {
  final String id;
  final String userId;
  final DateTime date;
  final String note;

  const DailyNoteResponse({
    required this.id,
    required this.userId,
    required this.date,
    required this.note,
  });

  factory DailyNoteResponse.fromJson(Map<String, dynamic> json) => DailyNoteResponse(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String,
      );
}
