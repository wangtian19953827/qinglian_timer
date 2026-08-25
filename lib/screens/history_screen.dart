import 'package:flutter/material.dart';

import '../models/training_record.dart';
import '../services/history_store.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/lace_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryStore _store = HistoryStore();
  List<TrainingRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final records = await _store.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空训练历史？'),
        content: const Text('此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _store.clear();
    await _reload();
  }

  Future<void> _delete(TrainingRecord record) async {
    await _store.delete(record.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '返回',
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceStrong,
                        foregroundColor: AppColors.accent,
                        fixedSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '训练历史',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    if (_records.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('清空'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _records.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            itemCount: _records.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildRecordCard(_records[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 42,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '还没有训练记录',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '完成一次训练后会自动保存在这里',
            style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(TrainingRecord record) {
    final best = record.laps.isEmpty
        ? null
        : record.laps.reduce((a, b) => a <= b ? a : b);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.finishedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '总时长 ${_formatDuration(record.total)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.laps.length} 段 · 最佳 ${best == null ? '-' : _formatDuration(best)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '删除',
            onPressed: () => _delete(record),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceStrong,
              foregroundColor: AppColors.inkSoft,
              fixedSize: const Size(42, 42),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

String _formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (hours > 0) {
    return '$hours:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}