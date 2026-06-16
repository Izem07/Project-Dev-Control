import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';
import '../models/app_state.dart';
import '../providers/admin_provider.dart';
import '../theme.dart';
import '../widgets/feds_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_dot.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  String _activeLogId = 'server';
  final ScrollController _logScroll = ScrollController();

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final configs = provider.configs;

    String overallLabel;
    Color overallColor;
    if (provider.allOnline) {
      overallLabel = 'Full Systems Online';
      overallColor = statusOnline;
    } else if (provider.anyOnline) {
      overallLabel = 'Degraded';
      overallColor = fedsOrange;
    } else {
      overallLabel = 'Ready (Idle)';
      overallColor = textSecondary;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(overallLabel: overallLabel, overallColor: overallColor),
          const SizedBox(height: 30),
          _AppGrid(configs: configs, provider: provider),
          const SizedBox(height: 30),
          _BottomSplit(
            provider: provider,
            activeLogId: _activeLogId,
            onLogSwitch: (id) => setState(() => _activeLogId = id),
            logScroll: _logScroll,
            onScrollBottom: _scrollToBottom,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String overallLabel;
  final Color overallColor;

  const _Header({required this.overallLabel, required this.overallColor});

  @override
  Widget build(BuildContext context) {
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
                'ScoutOps Admin Menu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dev Control — FRC Team 201 The FEDS',
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
                'Overall Status: ',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: overallColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  overallLabel,
                  style: TextStyle(
                    color: overallColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppGrid extends StatelessWidget {
  final Map<String, AppConfig> configs;
  final AdminProvider provider;

  const _AppGrid({required this.configs, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: configs.entries
          .map((e) => _AppCard(id: e.key, config: e.value, provider: provider))
          .toList(),
    );
  }
}

class _AppCard extends StatelessWidget {
  final String id;
  final AppConfig config;
  final AdminProvider provider;

  const _AppCard({
    required this.id,
    required this.config,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final status = provider.statusOf(id);
    final isBuild = config.isBuildOnly;
    final isIos = id == 'ios';

    return SizedBox(
      width: 320,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isBuild ? statusInfo : fedsOrange)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: (isBuild ? statusInfo : fedsOrange)
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          isBuild ? 'Flutter' : 'Port ${config.port}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isBuild
                                ? (isIos ? statusIos : statusInfo)
                                : fedsOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBuild)
                  InfoDot(color: isIos ? statusIos : statusInfo)
                else
                  StatusDot(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _desc(id),
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _actions(context, status, isBuild, isIos),
          ],
        ),
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    ProcessStatus status,
    bool isBuild,
    bool isIos,
  ) {
    if (isBuild) {
      return Row(
        children: [
          FedsButton(
            label: isIos ? 'Compile IPA' : 'Compile APK',
            style: isIos ? FedsButtonStyle.ios : FedsButtonStyle.primary,
            onPressed: () => _confirmBuild(context, isIos),
          ),
        ],
      );
    }

    final isRunning = status != ProcessStatus.offline;
    return Row(
      children: [
        FedsButton(
          label: isRunning
              ? 'Stop App'
              : (id == 'server' ? 'Start Server' : 'Start App'),
          style: isRunning ? FedsButtonStyle.stop : FedsButtonStyle.primary,
          onPressed: () =>
              isRunning ? provider.stopApp(id) : provider.startApp(id),
        ),
        const SizedBox(width: 10),
        FedsButton(
          label: 'Open',
          style: FedsButtonStyle.secondary,
          onPressed: status == ProcessStatus.online
              ? () => launchUrl(Uri.parse('http://localhost:${config.port}/'))
              : null,
        ),
      ],
    );
  }

  void _confirmBuild(BuildContext context, bool isIos) {
    final label = isIos ? 'iOS IPA' : 'Android APK';
    final cmd = isIos
        ? 'flutter build ipa --no-tree-shake-icons'
        : 'flutter build apk --no-tree-shake-icons';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(
          'Compile $label',
          style: const TextStyle(color: textPrimary),
        ),
        content: Text(
          "This will run '$cmd'.\nCheck the Live Dev Logs pane for output.",
          style: const TextStyle(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          FedsButton(
            label: 'Compile',
            style: isIos ? FedsButtonStyle.ios : FedsButtonStyle.primary,
            onPressed: () {
              Navigator.pop(context);
              provider.setActiveLog(id);
              provider.startApp(id);
            },
          ),
        ],
      ),
    );
  }

  String _desc(String id) {
    const descs = {
      'server':
          'Python backend server managing local DB and Bluetooth PAN client syncs.',
      'lookup':
          'Next.js application for querying scout reports and data search.',
      'dash': 'Flutter analytics dashboard showing graphs and team rankings.',
      'viewer': 'Flutter application for viewing real-time team match sheets.',
      'scan': 'Flutter web scanning tool to ingest match data via QR codes.',
      'android': 'Android app for field tablets. Builds APK for distribution.',
      'ios':
          'iOS app for iPads and iPhones. Requires macOS to sign and deploy.',
    };
    return descs[id] ?? '';
  }
}

class _BottomSplit extends StatelessWidget {
  final AdminProvider provider;
  final String activeLogId;
  final ValueChanged<String> onLogSwitch;
  final ScrollController logScroll;
  final VoidCallback onScrollBottom;

  const _BottomSplit({
    required this.provider,
    required this.activeLogId,
    required this.onLogSwitch,
    required this.logScroll,
    required this.onScrollBottom,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 12,
            child: _WorkspacePane(
              configs: provider.configs,
              provider: provider,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 8,
            child: _LogPane(
              provider: provider,
              activeLogId: activeLogId,
              onSwitch: onLogSwitch,
              scrollController: logScroll,
              onScrollBottom: onScrollBottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspacePane extends StatefulWidget {
  final Map<String, AppConfig> configs;
  final AdminProvider provider;

  const _WorkspacePane({required this.configs, required this.provider});

  @override
  State<_WorkspacePane> createState() => _WorkspacePaneState();
}

class _WorkspacePaneState extends State<_WorkspacePane> {
  String? _selectedApp;

  @override
  Widget build(BuildContext context) {
    final onlineApps = widget.configs.entries
        .where(
          (e) =>
              !e.value.isBuildOnly &&
              widget.provider.statusOf(e.key) == ProcessStatus.online,
        )
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Merged Workspace',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              DropdownButton<String?>(
                value: _selectedApp,
                hint: const Text(
                  '— Choose App to Embed —',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                dropdownColor: const Color(0xFF161B22),
                style: const TextStyle(color: textPrimary, fontSize: 13),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      '— None —',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                  ...onlineApps.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text('${e.value.name} (Port ${e.value.port})'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedApp = v),
              ),
            ],
          ),
          const Divider(height: 24, color: cardBorder),
          Expanded(
            child: _selectedApp == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔗', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 12),
                        Text(
                          'Select an online app above to view it here.',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌐', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'http://localhost:${widget.configs[_selectedApp]?.port}/',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => launchUrl(
                              Uri.parse(
                                'http://localhost:${widget.configs[_selectedApp]?.port}/',
                              ),
                            ),
                            child: const Text('Open in Browser'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogPane extends StatelessWidget {
  final AdminProvider provider;
  final String activeLogId;
  final ValueChanged<String> onSwitch;
  final ScrollController scrollController;
  final VoidCallback onScrollBottom;

  const _LogPane({
    required this.provider,
    required this.activeLogId,
    required this.onSwitch,
    required this.scrollController,
    required this.onScrollBottom,
  });

  @override
  Widget build(BuildContext context) {
    final logs = provider.logsOf(activeLogId);

    WidgetsBinding.instance.addPostFrameCallback((_) => onScrollBottom());

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Dev Logs',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: activeLogId,
                    dropdownColor: const Color(0xFF161B22),
                    style: const TextStyle(color: textPrimary, fontSize: 12),
                    underline: const SizedBox(),
                    items: provider.configs.keys
                        .map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text(provider.configs[id]!.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => v != null ? onSwitch(v) : null,
                  ),
                  const SizedBox(width: 8),
                  FedsButton(
                    label: 'Clear',
                    style: FedsButtonStyle.secondary,
                    small: true,
                    onPressed: () => provider.clearLogs(activeLogId),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: cardBorder),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF050508),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              padding: const EdgeInsets.all(12),
              child: logs.isEmpty
                  ? Text(
                      '[System] Listening for logs from ${provider.configs[activeLogId]?.name ?? activeLogId}...',
                      style: const TextStyle(
                        color: consoleBlue,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: logs.length,
                      itemBuilder: (_, i) {
                        final line = logs[i];
                        Color c;
                        switch (line.type) {
                          case LogLineType.error:
                            c = consoleRed;
                          case LogLineType.system:
                            c = consoleBlue;
                          case LogLineType.normal:
                            c = consoleGreen;
                        }
                        return Text(
                          line.text,
                          style: TextStyle(
                            color: c,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.5,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
