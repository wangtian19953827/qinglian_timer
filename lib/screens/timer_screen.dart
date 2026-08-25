import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/training_record.dart';
import '../services/history_store.dart';
import '../services/voice_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/lace_background.dart';
import 'history_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  final VoiceService _voice = VoiceService();
  final HistoryStore _history = HistoryStore();
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _ticker;
  Timer? _restTicker;
  Duration _elapsed = Duration.zero;
  Duration _restRemaining = Duration.zero;
  final List<Duration> _laps = [];
  int _restDuration = 60;
  bool _isRunning = false;
  bool _restRunning = false;
  bool _voiceReady = false;
  String _voiceStatus = '正在准备语音';
  String _lastCommand = '';
  DateTime? _lastCommandAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initVoice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _restTicker?.cancel();
    _voice.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _voice.resume(onText: _onVoiceText);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _voice.pause();
    }
  }

  Future<void> _initVoice() async {
    final ok = await _voice.initialize(onError: _onVoiceError);
    if (!mounted) {
      return;
    }
    if (!ok) {
      setState(() {
        _voiceReady = false;
        _voiceStatus = '语音不可用';
      });
      return;
    }
    setState(() => _voiceReady = true);
    await _voice.startListening(_onVoiceText);
    if (mounted) {
      setState(() => _voiceStatus = '正在聆听');
    }
  }

  void _onVoiceError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceReady = false;
      _voiceStatus = '语音暂不可用';
    });
  }

  void _onVoiceText(String text) {
    final normalized = text.replaceAll(RegExp(r'[\s，。！？,.!?、·]'), '');
    if (normalized.isEmpty) {
      return;
    }
    final now = DateTime.now();
    if (_lastCommand == normalized &&
        _lastCommandAt != null &&
        now.difference(_lastCommandAt!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastCommand = normalized;
    _lastCommandAt = now;

    if (normalized.contains('开始')) {
      _start();
    } else if (normalized.contains('停止')) {
      _stop();
    } else if (normalized.contains('分段')) {
      _lap();
    } else if (normalized.contains('重置')) {
      _reset();
    }
  }

  void _start() {
    if (_isRunning) {
      return;
    }
    _restTicker?.cancel();
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _elapsed = _stopwatch.elapsed);
      }
    });
    setState(() {
      _isRunning = true;
      _restRunning = false;
      _restRemaining = Duration.zero;
    });
    HapticFeedback.mediumImpact();
  }

  void _stop() {
    if (!_isRunning) {
      return;
    }
    _stopwatch.stop();
    _ticker?.cancel();
    setState(() => _isRunning = false);
    if (_restDuration > 0) {
      _startRest();
    }
    HapticFeedback.mediumImpact();
  }

  void _startRest() {
    _restTicker?.cancel();
    setState(() {
      _restRunning = true;
      _restRemaining = Duration(seconds: _restDuration);
    });
    _restTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_restRemaining.inSeconds <= 1) {
          _restRemaining = Duration.zero;
          _finishRest();
        } else {
          _restRemaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  void _finishRest() {
    _restTicker?.cancel();
    _restRunning = false;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('休息结束，可以开始下一组')),
    );
  }

  void _lap() {
    if (!_isRunning) {
      return;
    }
    final previous = _laps.isEmpty ? Duration.zero : _laps.last;
    setState(() {
      _laps.add(_stopwatch.elapsed - previous);
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('第 ${_laps.length} 段已记录')),
    );
  }

  Future<void> _reset() async {
    final hasSession = _elapsed >= const Duration(seconds: 3) || _laps.isNotEmpty;
    if (hasSession) {
      await _saveSession();
    }
    _ticker?.cancel();
    _restTicker?.cancel();
    _stopwatch.reset();
    setState(() {
      _elapsed = Duration.zero;
      _laps.clear();
      _isRunning = false;
      _restRunning = false;
      _restRemaining = Duration.zero;
      _lastCommand = '';
      _lastCommandAt = null;
    });
    if (!hasSession && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('计时已重置')),
      );
    }
  }

  Future<void> _saveSession() async {
    final record = TrainingRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      finishedAt: DateTime.now(),
      total: _elapsed,
      laps: List<Duration>.of(_laps),
      rest: Duration(seconds: _restDuration),
    );
    await _history.save(record);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本次训练已保存到历史')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    children: [
                      _buildTimerCard(context),
                      const SizedBox(height: 16),
                      _buildRestCard(context),
                      const SizedBox(height: 16),
                      _buildVoiceCard(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 16, 6),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '轻练',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '语音健身计时器',
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '训练历史',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceStrong,
              foregroundColor: AppColors.accent,
              fixedSize: const Size(46, 46),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(BuildContext context) {
    final status = _isRunning
        ? '计时中'
        : _restRunning
            ? '休息中'
            : '已暂停';
    final statusColor = _isRunning
        ? AppColors.accent
        : _restRunning
            ? AppColors.warm
            : AppColors.inkSoft;
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '本次训练',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(36),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isRunning
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatTime(_elapsed, showTenths: true),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _laps.isEmpty ? '等待分段' : '${_laps.length} 段 · 已计时',
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          if (_laps.isNotEmpty) ...[
            _buildLapPreview(),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  icon: Icons.flag_rounded,
                  label: '分段',
                  onTap: _lap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _secondaryButton(
                  icon: Icons.restart_alt_rounded,
                  label: '重置',
                  onTap: _reset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _primaryButton(),
        ],
      ),
    );
  }

  Widget _buildLapPreview() {
    final shown = _laps.length > 5 ? _laps.sublist(_laps.length - 5) : _laps;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final lap in shown)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceStrong,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                _formatTime(lap),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                '组间休息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              if (_restRunning)
                Text(
                  _formatTime(_restRemaining),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warm,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                )
              else
                Text(
                  _restDuration == 0 ? '已关闭' : '停止后自动开始',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final seconds in const [0, 30, 45, 60, 90, 120])
                ChoiceChip(
                  selected: _restDuration == seconds,
                  onSelected: (_) => setState(() {
                    _restDuration = seconds;
                    if (_restRunning && seconds == 0) {
                      _restTicker?.cancel();
                      _restRunning = false;
                      _restRemaining = Duration.zero;
                    }
                  }),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _restDuration == seconds
                        ? Colors.white
                        : AppColors.ink,
                  ),
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surfaceStrong,
                  side: BorderSide(
                    color: _restDuration == seconds
                        ? AppColors.accent
                        : AppColors.line,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  label: Text(seconds == 0 ? '关闭' : '$seconds 秒'),
                ),
            ],
          ),
          if (_restRunning) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _restDuration == 0
                    ? 0
                    : _restRemaining.inSeconds / _restDuration,
                minHeight: 6,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation(AppColors.warm),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceCard(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '语音控制',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _voiceStatus,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          if (_voiceReady)
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryButton() {
    final running = _isRunning;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: running ? _stop : _start,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? '暂停' : '开始',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTime(Duration d, {bool showTenths = false}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  final tenths = (d.inMilliseconds % 1000) ~/ 100;
  final core = hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '${two(minutes)}:${two(seconds)}';
  return showTenths ? '$core.$tenths' : core;
}