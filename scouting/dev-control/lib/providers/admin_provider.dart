import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../models/app_state.dart';
import '../services/prefs_service.dart';
import '../services/process_service.dart';

class AdminProvider extends ChangeNotifier {
  final PrefsService _prefs;
  final ProcessService _proc;

  Map<String, AppConfig> configs = {};
  final Map<String, AppState> states = {};
  String activeLogAppId = 'server';
  Timer? _pollTimer;

  AdminProvider(this._prefs, this._proc) {
    _proc.onLog = (id, line) {
      states[id]?.addLog(line);
      if (id == activeLogAppId) notifyListeners();
    };
    _proc.onStatusChange = (id, status) {
      states[id]?.status = status;
      notifyListeners();
    };
  }

  Future<void> init() async {
    configs = _prefs.getAppConfigs();
    for (final id in configs.keys) {
      states[id] = AppState(id: id);
    }
    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    for (final id in configs.keys) {
      final cfg = configs[id]!;
      if (cfg.isBuildOnly) continue;
      final running = _proc.isRunning(id);
      final online = await _proc.isPortListening(cfg.port);
      final prev = states[id]?.status;
      final next = online
          ? ProcessStatus.online
          : running
          ? ProcessStatus.running
          : ProcessStatus.offline;
      if (next != prev) {
        states[id]?.status = next;
        notifyListeners();
      }
    }
  }

  Future<bool> startApp(String id) async {
    final cfg = configs[id];
    if (cfg == null) return false;
    final ok = await _proc.start(id, cfg.command, cfg.cwd);
    if (ok) {
      states[id]?.status = ProcessStatus.running;
      notifyListeners();
    }
    return ok;
  }

  Future<void> stopApp(String id) async {
    await _proc.stop(id);
    states[id]?.status = ProcessStatus.offline;
    notifyListeners();
  }

  void setActiveLog(String id) {
    activeLogAppId = id;
    notifyListeners();
  }

  void clearLogs(String id) {
    states[id]?.clearLogs();
    notifyListeners();
  }

  ProcessStatus statusOf(String id) =>
      states[id]?.status ?? ProcessStatus.offline;

  List<LogLine> logsOf(String id) => states[id]?.logs ?? [];

  bool get anyOnline =>
      states.values.any((s) => s.status == ProcessStatus.online);
  bool get allOnline => configs.keys
      .where((id) => !configs[id]!.isBuildOnly)
      .every((id) => states[id]?.status == ProcessStatus.online);

  Future<void> saveConfigs(Map<String, AppConfig> updated) async {
    configs = updated;
    await _prefs.saveAppConfigs(updated);
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _proc.dispose();
    super.dispose();
  }
}
