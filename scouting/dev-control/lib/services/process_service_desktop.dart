import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import '../models/app_state.dart';

typedef LogCallback = void Function(String appId, String line);
typedef StatusCallback = void Function(String appId, ProcessStatus status);

class ProcessService {
  final Map<String, Process> _processes = {};
  final Map<String, List<StreamSubscription>> _subs = {};

  LogCallback? onLog;
  StatusCallback? onStatusChange;

  Future<bool> start(String appId, String command, String cwd) async {
    if (_processes.containsKey(appId)) return false;

    final resolved = p.isAbsolute(cwd)
        ? cwd
        : p.normalize(p.join(Directory.current.path, cwd));

    try {
      final process = await Process.start(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows ? ['/c', command] : ['-c', command],
        workingDirectory: resolved,
        runInShell: false,
      );

      _processes[appId] = process;
      _subs[appId] = [];

      void pipe(Stream<List<int>> stream) {
        _subs[appId]!.add(
          stream.transform(const SystemEncoding().decoder).listen((chunk) {
            onLog?.call(appId, chunk);
          }),
        );
      }

      pipe(process.stdout);
      pipe(process.stderr);

      process.exitCode.then((code) {
        onLog?.call(appId, '[Process exited with code $code]\n');
        _cleanup(appId);
        onStatusChange?.call(appId, ProcessStatus.offline);
      });

      return true;
    } catch (e) {
      onLog?.call(appId, '[Process error: $e]\n');
      return false;
    }
  }

  Future<void> stop(String appId) async {
    final proc = _processes[appId];
    if (proc == null) return;

    if (Platform.isWindows) {
      await Process.run('taskkill', ['/pid', '${proc.pid}', '/f', '/t']);
    } else {
      proc.kill(ProcessSignal.sigint);
    }

    _cleanup(appId);
  }

  bool isRunning(String appId) => _processes.containsKey(appId);

  Future<bool> isPortListening(int port) async {
    if (port == 0) return false;
    try {
      final socket = await Socket.connect(
        '127.0.0.1',
        port,
        timeout: const Duration(milliseconds: 800),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _cleanup(String appId) {
    for (final sub in _subs[appId] ?? []) {
      sub.cancel();
    }
    _subs.remove(appId);
    _processes.remove(appId);
  }

  void dispose() {
    for (final id in _processes.keys.toList()) {
      stop(id);
    }
  }
}
