// Web stub for ProcessService — no dart:io, no process spawning.
// All operations are no-ops; the UI uses kIsWeb to adapt accordingly.
import '../models/app_state.dart';

typedef LogCallback = void Function(String appId, String line);
typedef StatusCallback = void Function(String appId, ProcessStatus status);

class ProcessService {
  LogCallback? onLog;
  StatusCallback? onStatusChange;

  Future<bool> start(String appId, String command, String cwd) async {
    onLog?.call(appId, '[Web Mode] Process control is not available in the browser.\n');
    return false;
  }

  Future<void> stop(String appId) async {
    onLog?.call(appId, '[Web Mode] Process control is not available in the browser.\n');
  }

  bool isRunning(String appId) => false;

  Future<bool> isPortListening(int port) async => false;

  void dispose() {}
}
