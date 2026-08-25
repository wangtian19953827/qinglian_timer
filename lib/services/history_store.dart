import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_record.dart';

class HistoryStore {
  static const String _key = 'training_history_v1';

  Future<List<TrainingRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => TrainingRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(TrainingRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await load();
    records.insert(0, record);
    final payload = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_key, payload);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await load();
    records.removeWhere((record) => record.id == id);
    final payload = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_key, payload);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}