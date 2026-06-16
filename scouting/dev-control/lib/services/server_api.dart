import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerHealth {
  final String status;
  final String battery;
  final String cpu;
  final String memory;

  const ServerHealth({
    required this.status,
    required this.battery,
    required this.cpu,
    required this.memory,
  });

  factory ServerHealth.fromJson(Map<String, dynamic> j) => ServerHealth(
    status: j['ServerStatus']?.toString() ?? '—',
    battery: j['ServerBattery']?.toString() ?? '—',
    cpu: j['ServerCPUUsage']?.toString() ?? '—',
    memory: j['ServerMemoryUsage']?.toString() ?? '—',
  );
}

class DeviceEntry {
  final String id;
  final String name;
  final String type;
  const DeviceEntry({required this.id, required this.name, required this.type});
}

class DataEntry {
  final String station;
  final String alliance;
  final dynamic raw;
  const DataEntry({
    required this.station,
    required this.alliance,
    required this.raw,
  });
}

class ServerApi {
  final String ip;
  final int port;

  ServerApi(this.ip, this.port);

  Uri _uri(String path) => Uri.parse('http://$ip:$port$path');

  Future<bool> ping() async {
    try {
      final res = await http.get(_uri('/')).timeout(const Duration(seconds: 4));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<ServerHealth?> getHealth() async {
    try {
      final res = await http
          .get(_uri('/api/get_health'))
          .timeout(const Duration(seconds: 3));
      return ServerHealth.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DeviceEntry>> getDevices() async {
    try {
      final res = await http
          .get(_uri('/api/devices'))
          .timeout(const Duration(seconds: 3));
      final raw = json.decode(res.body) as List;
      return raw
          .map(
            (d) => DeviceEntry(
              id: d[0].toString(),
              name: d[1].toString(),
              type: d[2].toString(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteDevice(String id) async {
    try {
      final res = await http
          .post(_uri('/api/delete_device/$id'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAllDevices() async {
    try {
      final res = await http
          .post(_uri('/api/clear_devices'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<DataEntry>> getData() async {
    try {
      final res = await http
          .get(_uri('/api/get_data'))
          .timeout(const Duration(seconds: 3));
      final raw = json.decode(res.body) as List;
      return raw.map((item) {
        try {
          final parsed =
              json.decode((item[1] as String).replaceAll("'", '"'))
                  as Map<String, dynamic>;
          return DataEntry(
            station: parsed['TypesselectedStation']?.toString() ?? '?',
            alliance: parsed['TypesallianceColor']?.toString() ?? 'unknown',
            raw: parsed,
          );
        } catch (_) {
          return const DataEntry(station: '?', alliance: 'unknown', raw: null);
        }
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendEventKey(String key) async {
    try {
      final tbaRes = await http
          .get(
            Uri.parse(
              'https://www.thebluealliance.com/api/v3/event/$key/matches',
            ),
            headers: {
              'X-TBA-Auth-Key':
                  '2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W',
            },
          )
          .timeout(const Duration(seconds: 8));

      final req = http.MultipartRequest('POST', _uri('/post_event_file'));
      req.files.add(
        http.MultipartFile.fromString(
          'Event',
          tbaRes.body,
          filename: 'event.json',
        ),
      );
      req.fields['EventKey'] = key;
      final res = await req.send().timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendEventFile(List<int> bytes, String filename) async {
    try {
      final req = http.MultipartRequest('POST', _uri('/post_event_file'));
      req.files.add(
        http.MultipartFile.fromBytes('Event', bytes, filename: filename),
      );
      final res = await req.send().timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearEvent() async {
    try {
      final res = await http
          .post(_uri('/clear_event_file'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
