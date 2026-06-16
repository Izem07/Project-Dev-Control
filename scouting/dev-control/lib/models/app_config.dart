class AppConfig {
  final String id;
  String name;
  int port;
  String command;
  String cwd;

  AppConfig({
    required this.id,
    required this.name,
    required this.port,
    required this.command,
    required this.cwd,
  });

  bool get isBuildOnly => port == 0;

  factory AppConfig.fromJson(String id, Map<String, dynamic> json) {
    return AppConfig(
      id: id,
      name: json['name'] as String,
      port: json['port'] as int,
      command: json['command'] as String,
      cwd: json['cwd'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'port': port,
    'command': command,
    'cwd': cwd,
  };

  AppConfig copyWith({String? name, int? port, String? command, String? cwd}) {
    return AppConfig(
      id: id,
      name: name ?? this.name,
      port: port ?? this.port,
      command: command ?? this.command,
      cwd: cwd ?? this.cwd,
    );
  }

  static Map<String, AppConfig> defaults() => {
    'server': AppConfig(
      id: 'server',
      name: 'Scout Ops Server',
      port: 5000,
      command: 'python server.py',
      cwd: '../server',
    ),
    'lookup': AppConfig(
      id: 'lookup',
      name: 'Scout Lookup (Next.js)',
      port: 3000,
      command: 'npm run dev',
      cwd: '../scout-lookup',
    ),
    'dash': AppConfig(
      id: 'dash',
      name: 'Scout Analytics',
      port: 8080,
      command: 'flutter run -d web-server --web-port=8080',
      cwd: '../dash',
    ),
    'viewer': AppConfig(
      id: 'viewer',
      name: 'Match Viewer',
      port: 8081,
      command: 'flutter run -d web-server --web-port=8081',
      cwd: '../match-viewer',
    ),
    'scan': AppConfig(
      id: 'scan',
      name: 'Scout Ops Scan',
      port: 8082,
      command: 'flutter run -d web-server --web-port=8082',
      cwd: '../scan',
    ),
    'android': AppConfig(
      id: 'android',
      name: 'Scout Ops Android',
      port: 0,
      command: 'flutter build apk --no-tree-shake-icons',
      cwd: '../android',
    ),
    'ios': AppConfig(
      id: 'ios',
      name: 'Scout Ops iOS',
      port: 0,
      command: 'flutter build ipa --no-tree-shake-icons',
      cwd: '../android',
    ),
  };
}
