import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';
import '../services/server_api.dart';
import '../theme.dart';
import '../widgets/feds_button.dart';
import '../widgets/glass_card.dart';

class ServerHealthScreen extends StatefulWidget {
  const ServerHealthScreen({super.key});

  @override
  State<ServerHealthScreen> createState() => _ServerHealthScreenState();
}

class _ServerHealthScreenState extends State<ServerHealthScreen> {
  ServerApi? _api;
  ServerHealth? _health;
  List<DeviceEntry> _devices = [];
  List<DataEntry> _data = [];
  String? _toastMsg;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = context.read<PrefsService>();
    _api = ServerApi(prefs.savedIp, int.tryParse(prefs.savedPort) ?? 5000);
    await _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_api == null) return;
    final results = await Future.wait([
      _api!.getHealth(),
      _api!.getDevices(),
      _api!.getData(),
    ]);
    if (!mounted) return;
    setState(() {
      _health = results[0] as ServerHealth?;
      _devices = results[1] as List<DeviceEntry>;
      _data = results[2] as List<DataEntry>;
    });
  }

  void _toast(String msg) {
    setState(() => _toastMsg = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader(),
              const SizedBox(height: 24),
              _topRow(),
              const SizedBox(height: 24),
              _bottomRow(),
            ],
          ),
        ),
        if (_toastMsg != null)
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: fedsOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fedsOrange.withValues(alpha: 0.3)),
              ),
              child: Text(
                _toastMsg!,
                style: const TextStyle(
                  color: fedsOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => primaryGradient.createShader(b),
              blendMode: BlendMode.srcIn,
              child: const Text(
                'Server Health',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Live status for the Scout Ops Server and all connected field devices',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              const Text(
                'Server: ',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Text(
                _health?.status ?? 'Checking...',
                style: TextStyle(
                  color: _health != null ? statusOnline : fedsOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ServerInfoCard(
            health: _health,
            ip: _api?.ip ?? '—',
            port: _api?.port.toString() ?? '—',
            onRefresh: _refresh,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DevicesCard(
            devices: _devices,
            api: _api,
            onRefresh: _refresh,
            onToast: _toast,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DataCard(data: _data, onRefresh: _refresh),
        ),
      ],
    );
  }

  Widget _bottomRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MatchCard(api: _api, onToast: _toast),
        ),
        const SizedBox(width: 20),
        const Expanded(child: _ScoutersCard()),
        const SizedBox(width: 20),
        Expanded(
          child: _RecordingCard(data: _data, onToast: _toast),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;

  const _SectionTitle(this.icon, this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (b) => primaryGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerInfoCard extends StatelessWidget {
  final ServerHealth? health;
  final String ip;
  final String port;
  final VoidCallback onRefresh;

  const _ServerInfoCard({
    required this.health,
    required this.ip,
    required this.port,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('🖥️', 'Server Info'),
          const Divider(height: 20, color: cardBorder),
          _InfoRow('IP Address', ip),
          _InfoRow('Port', port),
          _InfoRow('Status', health?.status ?? '—'),
          _InfoRow('Battery', health?.battery ?? '—'),
          _InfoRow('CPU Usage', health?.cpu ?? '—'),
          _InfoRow('Memory', health?.memory ?? '—'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FedsButton(
                label: 'Refresh',
                style: FedsButtonStyle.secondary,
                small: true,
                onPressed: onRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  final List<DeviceEntry> devices;
  final ServerApi? api;
  final VoidCallback onRefresh;
  final ValueChanged<String> onToast;

  const _DevicesCard({
    required this.devices,
    required this.api,
    required this.onRefresh,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('📱', 'Connected Devices')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: fedsOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${devices.length}',
                  style: const TextStyle(
                    color: fedsOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: cardBorder),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No devices connected',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            )
          else
            ...devices.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${d.name} — ${d.type}',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    FedsButton(
                      label: 'Delete',
                      style: FedsButtonStyle.stop,
                      small: true,
                      onPressed: () async {
                        await api?.deleteDevice(d.id);
                        onToast('Device ${d.name} removed.');
                        onRefresh();
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FedsButton(
                label: 'Refresh',
                style: FedsButtonStyle.secondary,
                small: true,
                onPressed: onRefresh,
              ),
              FedsButton(
                label: 'Delete All',
                style: FedsButtonStyle.stop,
                small: true,
                onPressed: () async {
                  await api?.deleteAllDevices();
                  onToast('All devices deleted.');
                  onRefresh();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final List<DataEntry> data;
  final VoidCallback onRefresh;

  const _DataCard({required this.data, required this.onRefresh});

  Color _allianceColor(String a) {
    if (a.toLowerCase() == 'red') return statusOffline;
    if (a.toLowerCase() == 'blue') return statusInfo;
    return textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('📊', 'Data Collected')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: fedsOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${data.length}',
                  style: const TextStyle(
                    color: fedsOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: cardBorder),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No data records yet',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data
                  .map(
                    (d) => GestureDetector(
                      onTap: () => _showPopup(context, d),
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _allianceColor(d.alliance),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          d.station,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          FedsButton(
            label: 'Refresh',
            style: FedsButtonStyle.secondary,
            small: true,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }

  void _showPopup(BuildContext context, DataEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(
          'Station ${entry.station}',
          style: const TextStyle(color: textPrimary),
        ),
        content: SingleChildScrollView(
          child: Text(
            entry.raw.toString(),
            style: const TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: fedsOrange)),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final ServerApi? api;
  final ValueChanged<String> onToast;

  const _MatchCard({required this.api, required this.onToast});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  final _keyCtrl = TextEditingController();
  String? _fileName;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('🏆', 'Current Match'),
          const Divider(height: 20, color: cardBorder),
          const Text(
            'MATCH KEY',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _keyCtrl,
            style: const TextStyle(color: textPrimary, fontSize: 13),
            decoration: const InputDecoration(hintText: 'e.g. 2026miket_qm1'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FedsButton(
                label: 'Send Event',
                small: true,
                onPressed: () async {
                  final ok = await widget.api?.sendEventKey(
                    _keyCtrl.text.trim(),
                  );
                  widget.onToast(
                    ok == true ? 'Event uploaded.' : 'Upload failed.',
                  );
                },
              ),
              FedsButton(
                label: 'Clear',
                style: FedsButtonStyle.stop,
                small: true,
                onPressed: () async {
                  await widget.api?.clearEvent();
                  widget.onToast('Event cleared.');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'UPLOAD JSON',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FedsButton(
                label: _fileName != null ? '📄 $_fileName' : '📁 Choose File',
                style: FedsButtonStyle.secondary,
                small: true,
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.bytes != null) {
                    setState(() => _fileName = result.files.single.name);
                    final ok = await widget.api?.sendEventFile(
                      result.files.single.bytes!,
                      result.files.single.name,
                    );
                    widget.onToast(
                      ok == true ? 'File uploaded.' : 'Upload failed.',
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoutersCard extends StatelessWidget {
  const _ScoutersCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('👥', 'Check Scouters'),
          const Divider(height: 20, color: cardBorder),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fedsOrange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: fedsOrange.withValues(alpha: 0.12)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🚧', style: TextStyle(fontSize: 18)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: fedsOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Scouter assignment verification is not yet implemented — API spec pending.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  final List<DataEntry> data;
  final ValueChanged<String> onToast;

  const _RecordingCard({required this.data, required this.onToast});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('💾', 'Data Recording'),
          const Divider(height: 20, color: cardBorder),
          const Text(
            'Export all collected scouting data as a CSV file for offline analysis.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          FedsButton(
            label: '⬇  Download CSV',
            onPressed: data.isEmpty ? null : () => _downloadCsv(),
          ),
        ],
      ),
    );
  }

  void _downloadCsv() {
    final rows = <List<String>>[];
    for (final entry in data) {
      if (entry.raw is Map) {
        final flat = _flatten(entry.raw as Map);
        if (rows.isEmpty) rows.add(flat.keys.toList());
        rows.add(flat.values.map((v) => '"$v"').toList());
      }
    }
    if (rows.isEmpty) return;
    final csv = rows.map((r) => r.join(',')).join('\n');
    onToast('CSV ready — $csv');
  }

  Map<String, dynamic> _flatten(Map map, [String prefix = '']) {
    final result = <String, dynamic>{};
    map.forEach((k, v) {
      final key = prefix.isEmpty ? k.toString() : '${prefix}_$k';
      if (v is Map) {
        result.addAll(_flatten(v, key));
      } else {
        result[key] = v;
      }
    });
    return result;
  }
}
