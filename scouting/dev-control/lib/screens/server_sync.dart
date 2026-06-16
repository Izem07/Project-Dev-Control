import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';
import '../services/server_api.dart';
import '../theme.dart';
import '../widgets/feds_button.dart';
import '../widgets/glass_card.dart';

enum ConnectStatus { idle, connecting, success, error }

class ServerSyncScreen extends StatefulWidget {
  final VoidCallback onConnected;

  const ServerSyncScreen({super.key, required this.onConnected});

  @override
  State<ServerSyncScreen> createState() => _ServerSyncScreenState();
}

class _ServerSyncScreenState extends State<ServerSyncScreen> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  ConnectStatus _status = ConnectStatus.idle;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = context.read<PrefsService>();
    _ipCtrl.text = prefs.savedIp;
    _portCtrl.text = prefs.savedPort;
  }

  Future<void> _connect() async {
    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 0;
    if (ip.isEmpty || port == 0) return;

    setState(() {
      _status = ConnectStatus.connecting;
      _statusMsg = 'Connecting...';
    });

    final prefs = context.read<PrefsService>();
    await prefs.saveIpPort(ip, port.toString());

    final ok = await ServerApi(ip, port).ping();

    if (!mounted) return;
    if (ok) {
      setState(() {
        _status = ConnectStatus.success;
        _statusMsg = 'Connected! Redirecting...';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onConnected();
    } else {
      setState(() {
        _status = ConnectStatus.error;
        _statusMsg =
            'Could not reach $ip:$port — make sure Scout Ops Server is running.';
      });
    }
  }

  Color get _statusColor {
    switch (_status) {
      case ConnectStatus.success:
        return statusOnline;
      case ConnectStatus.error:
        return statusOffline;
      case ConnectStatus.connecting:
        return fedsOrange;
      case ConnectStatus.idle:
        return Colors.transparent;
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => primaryGradient.createShader(b),
            blendMode: BlendMode.srcIn,
            child: const Text('Server Sync',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(height: 4),
          const Text(
              'Connect this Dev Control station to a running Scout Ops Server',
              style: TextStyle(color: textSecondary, fontSize: 13)),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ConnectCard(
                  ipCtrl: _ipCtrl,
                  portCtrl: _portCtrl,
                  status: _status,
                  statusMsg: _statusMsg,
                  statusColor: _statusColor,
                  onConnect: _connect,
                  onLoadSaved: _loadSaved,
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(child: _HowToCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  final TextEditingController ipCtrl;
  final TextEditingController portCtrl;
  final ConnectStatus status;
  final String statusMsg;
  final Color statusColor;
  final VoidCallback onConnect;
  final VoidCallback onLoadSaved;

  const _ConnectCard({
    required this.ipCtrl,
    required this.portCtrl,
    required this.status,
    required this.statusMsg,
    required this.statusColor,
    required this.onConnect,
    required this.onLoadSaved,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📡', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => primaryGradient.createShader(b),
                    blendMode: BlendMode.srcIn,
                    child: const Text('Connect to Server',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const Text(
                      'Enter the IP and port of your Scout Ops Python server',
                      style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Divider(height: 32, color: cardBorder),
          const _FieldLabel('SERVER IP ADDRESS'),
          const SizedBox(height: 8),
          TextField(
            controller: ipCtrl,
            style: const TextStyle(color: textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'e.g. 192.168.1.100'),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('PORT'),
          const SizedBox(height: 8),
          SizedBox(
            width: 180,
            child: TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: textPrimary, fontSize: 14),
              decoration: const InputDecoration(hintText: '5000'),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              FedsButton(label: '⚡  Connect', onPressed: onConnect),
              const SizedBox(width: 12),
              FedsButton(
                  label: 'Load Saved',
                  style: FedsButtonStyle.secondary,
                  onPressed: onLoadSaved),
            ],
          ),
          if (statusMsg.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(statusMsg,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  const _HowToCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Start the Scout Ops Server from the Control Panel',
      'Find the server machine\'s IP on your local network (e.g. 192.168.x.x)',
      'Enter the IP and port 5000 above and click Connect',
      'You\'ll be redirected to Server Health on success',
    ];

    return GlassCard(
      borderColor: fedsOrange.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => primaryGradient.createShader(b),
                    blendMode: BlendMode.srcIn,
                    child: const Text('How to Connect',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const Text('Quick guide for field setup',
                      style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Divider(height: 32, color: cardBorder),
          ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, gradient: primaryGradient),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fedsOrange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: fedsOrange.withValues(alpha: 0.12)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡', style: TextStyle(fontSize: 15)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Using Bluetooth PAN? The server IP is typically 192.168.44.1 on the host device.',
                    style: TextStyle(
                        color: textSecondary, fontSize: 12, height: 1.5),
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8));
  }
}
