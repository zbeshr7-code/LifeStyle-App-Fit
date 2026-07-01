import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerService {
  static const _keyDate = 'activity_date';
  static const _keyBaseline = 'pedometer_baseline';
  static const _keyStepsToday = 'steps_today';

  StreamSubscription<StepCount>? _subscription;
  final _stepsController = StreamController<int>.broadcast();

  Stream<int> get stepsStream => _stepsController.stream;

  bool _available = true;
  bool get isAvailable => _available;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _stepsToday = 0;
  int get stepsToday => _stepsToday;

  Future<bool> _ensurePermission() async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;

    status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<void> start() async {
    try {
      if (!await _ensurePermission()) {
        _available = false;
        _errorMessage = 'activity_permission_denied';
        return;
      }

      await _loadPrefs();
      _subscription?.cancel();
      _subscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (Object error) {
          _available = false;
          _errorMessage = 'activity_pedometer_unavailable';
        },
      );
    } catch (error) {
      _available = false;
      _errorMessage = 'activity_pedometer_unavailable';
    }
  }

  Future<void> _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    final storedDate = prefs.getString(_keyDate);

    if (storedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyBaseline, event.steps);
      await prefs.setInt(_keyStepsToday, 0);
      _stepsToday = 0;
    } else {
      var baseline = prefs.getInt(_keyBaseline);
      if (baseline == null) {
        final stored = prefs.getInt(_keyStepsToday) ?? 0;
        baseline = event.steps - stored;
        if (baseline < 0) baseline = event.steps;
        await prefs.setInt(_keyBaseline, baseline);
      }

      var delta = event.steps - baseline;
      if (delta < 0) {
        final previous = prefs.getInt(_keyStepsToday) ?? 0;
        baseline = event.steps - previous;
        if (baseline < 0) baseline = event.steps;
        await prefs.setInt(_keyBaseline, baseline);
        delta = event.steps - baseline;
      }
      _stepsToday = delta;
      await prefs.setInt(_keyStepsToday, _stepsToday);
    }

    _stepsController.add(_stepsToday);
  }

  Future<void> reconcileWithServer({
    required int serverSteps,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(date);
    final storedDate = prefs.getString(_keyDate);

    if (storedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyStepsToday, serverSteps);
      await prefs.remove(_keyBaseline);
      _stepsToday = serverSteps;
    } else if (serverSteps > _stepsToday) {
      _stepsToday = serverSteps;
      await prefs.setInt(_keyStepsToday, serverSteps);
      await prefs.remove(_keyBaseline);
    }

    _stepsController.add(_stepsToday);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    if (prefs.getString(_keyDate) == today) {
      _stepsToday = prefs.getInt(_keyStepsToday) ?? 0;
      _stepsController.add(_stepsToday);
    }
  }

  Future<void> resetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDate, _formatDate(DateTime.now()));
    await prefs.setInt(_keyStepsToday, 0);
    await prefs.remove(_keyBaseline);
    _stepsToday = 0;
    _stepsController.add(0);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _subscription?.cancel();
    _stepsController.close();
  }
}
