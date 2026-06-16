import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/admin_provider.dart';
import 'screens/control_panel.dart';
import 'screens/server_health.dart';
import 'screens/server_sync.dart';
import 'screens/settings_screen.dart';
import 'services/prefs_service.dart';
import 'services/process_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = PrefsService();
  await prefs.init();
  final proc = ProcessService();
  final admin = AdminProvider(prefs, proc);
  await admin.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: admin),
        Provider.value(value: prefs),
      ],
      child: const ScoutOpsAdminApp(),
    ),
  );
}

class ScoutOpsAdminApp extends StatelessWidget {
  const ScoutOpsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScoutOps Admin Menu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(index: _index, onSelect: (i) => setState(() => _index = i)),
          const VerticalDivider(width: 1, color: cardBorder),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_index) {
      case 0:
        return const ControlPanelScreen();
      case 1:
        return ServerSyncScreen(onConnected: () => setState(() => _index = 2));
      case 2:
        return const ServerHealthScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const ControlPanelScreen();
    }
  }
}

class _Sidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF0D0E12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 38,
                      height: 38,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              primaryGradient.createShader(b),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'SCOUTOPS',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'ADMIN MENU',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(gradient: primaryGradient),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Control Panel',
                  selected: index == 0,
                  onTap: () => onSelect(0),
                ),
                _NavItem(
                  icon: Icons.wifi_outlined,
                  activeIcon: Icons.wifi,
                  label: 'Server Sync',
                  selected: index == 1,
                  onTap: () => onSelect(1),
                ),
                _NavItem(
                  icon: Icons.monitor_heart_outlined,
                  activeIcon: Icons.monitor_heart,
                  label: 'Server Health',
                  selected: index == 2,
                  onTap: () => onSelect(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  selected: index == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'FRC Team 201 · The FEDS',
              style: GoogleFonts.outfit(fontSize: 11, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: selected
                  ? fedsOrange.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: selected
                  ? Border.all(color: fedsOrange.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 18,
                  color: selected ? fedsOrange : textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? textPrimary : textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
