import 'package:flutter_test/flutter_test.dart';
import 'package:qinglian_timer/models/training_record.dart';

void main() {
  test('TrainingRecord round trip', () {
    final record = TrainingRecord(
      id: '1',
      finishedAt: DateTime(2026, 8, 25),
      total: const Duration(seconds: 90),
      laps: const [Duration(seconds: 30), Duration(seconds: 60)],
      rest: const Duration(seconds: 60),
    );
    final restored = TrainingRecord.fromJson(record.toJson());
    expect(restored.total, record.total);
    expect(restored.laps, record.laps);
    expect(restored.rest, record.rest);
  });
}