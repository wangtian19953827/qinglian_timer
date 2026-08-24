class TrainingRecord {
  TrainingRecord({
    required this.id,
    required this.finishedAt,
    required this.total,
    required this.laps,
    required this.rest,
  });

  final String id;
  final DateTime finishedAt;
  final Duration total;
  final List<Duration> laps;
  final Duration rest;

  Map<String, dynamic> toJson() => {
        'id': id,
        'finishedAt': finishedAt.toIso8601String(),
        'totalSeconds': total.inSeconds,
        'laps': laps.map((lap) => lap.inSeconds).toList(),
        'restSeconds': rest.inSeconds,
      };

  factory TrainingRecord.fromJson(Map<String, dynamic> json) {
    return TrainingRecord(
      id: json['id'] as String,
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      total: Duration(seconds: json['totalSeconds'] as int),
      laps: (json['laps'] as List<dynamic>)
          .map((value) => Duration(seconds: value as int))
          .toList(),
      rest: Duration(seconds: json['restSeconds'] as int),
    );
  }
}