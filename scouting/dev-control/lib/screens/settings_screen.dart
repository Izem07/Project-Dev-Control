import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_config.dart';
import '../providers/admin_provider.dart';
import '../theme.dart';
import '../widgets/feds_button.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, _RowControllers> _ctrls = {};
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final configs = context.read<AdminProvider>().configs;
    for (final entry in configs.entries) {
      _ctrls[entry.key] = _RowControllers(entry.value);
    }
  }

  void _reset() {
    final defaults = AppConfig.defaults();
    setState(() {
      for (final entry in defaults.entries) {
        _ctrls[entry.key] = _RowControllers(entry.value);
      }
    });
  }

  Future<void> _save() async {
    final updated = <String, AppConfig>{};
    for (final entry in _ctrls.entries) {
      final c = entry.value;
      updated[entry.key] = AppConfig(
        id: entry.key,
        name: c.name,
        port: int.tryParse(c.portCtrl.text) ?? 0,
        command: c.cmdCtrl.text,
        cwd: c.cwdCtrl.text,
      );
    }
    await context.read<AdminProvider>().saveConfigs(updated);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
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
            child: const Text(
              'Configuration',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Customize ports, commands, and working directories for each sub-application',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 30),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => primaryGradient.createShader(b),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'Sub-App Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Commands run relative to the working directory (Cwd). Paths should be relative to scouting/dev-control.',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                _rowHeader(),
                const Divider(height: 16, color: cardBorder),
                ..._ctrls.entries.map(
                  (e) => _AppRow(id: e.key, ctrls: e.value),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FedsButton(
                      label: 'Reset to Defaults',
                      style: FedsButtonStyle.secondary,
                      onPressed: _reset,
                    ),
                    const SizedBox(width: 14),
                    FedsButton(
                      label: _saved ? '✓ Saved' : 'Save Configs',
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowHeader() {
    const style = TextStyle(
      color: textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return const Row(
      children: [
        SizedBox(width: 160, child: Text('Application', style: style)),
        SizedBox(width: 80, child: Text('Port', style: style)),
        Expanded(child: Text('Launch Command', style: style)),
        SizedBox(width: 20),
        Expanded(child: Text('Working Directory', style: style)),
      ],
    );
  }
}

class _AppRow extends StatelessWidget {
  final String id;
  final _RowControllers ctrls;

  const _AppRow({required this.id, required this.ctrls});

  @override
  Widget build(BuildContext context) {
    final isBuild = id == 'android' || id == 'ios';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              ctrls.name,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: isBuild
                ? const Text(
                    '—',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  )
                : TextField(
                    controller: ctrls.portCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrls.cmdCtrl,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrls.cwdCtrl,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowControllers {
  final String name;
  final TextEditingController portCtrl;
  final TextEditingController cmdCtrl;
  final TextEditingController cwdCtrl;

  _RowControllers(AppConfig cfg)
    : name = cfg.name,
      portCtrl = TextEditingController(text: cfg.port.toString()),
      cmdCtrl = TextEditingController(text: cfg.command),
      cwdCtrl = TextEditingController(text: cfg.cwd);

  void dispose() {
    portCtrl.dispose();
    cmdCtrl.dispose();
    cwdCtrl.dispose();
  }
}
