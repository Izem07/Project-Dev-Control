enum ProcessStatus { offline, running, online }

class AppState {
  final String id;
  ProcessStatus status;
  final List<LogLine> logs;

  AppState({required this.id, this.status = ProcessStatus.offline}) : logs = [];

  void addLog(String text) {
    logs.add(LogLine(text));
    if (logs.length > 200) logs.removeAt(0);
  }

  void clearLogs() => logs.clear();
}

class LogLine {
  final String text;
  final LogLineType type;
  final DateTime timestamp;

  LogLine(this.text) : timestamp = DateTime.now(), type = _classify(text);

  static LogLineType _classify(String t) {
    if (t.contains('[Process exited') || t.contains('[System]')) {
      return LogLineType.system;
    }
    if (t.toLowerCase().contains('error') ||
        t.contains('Exception') ||
        t.contains('[Process error:')) {
      return LogLineType.error;
    }
    return LogLineType.normal;
  }
}

enum LogLineType { normal, system, error }
