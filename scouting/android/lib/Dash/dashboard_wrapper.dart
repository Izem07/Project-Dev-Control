import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_service.dart';
import 'services/local_prefs.dart';
import 'screens/event_entry_screen.dart';

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  final DataService _dataService = DataService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final config = await LocalPrefs.resolveConfig();
    if (config != null) {
      _dataService.configure(
        eventKey: config.eventKey,
        tableName: config.tableName,
        neonConnString: config.neonConn,
        tbaApiKey: config.tbaKey,
      );

      final cached = await LocalPrefs.loadData(config.eventKey);
      if (cached != null) {
        _dataService.loadFromCache(
          scoutingByTeam: cached.scoutingByTeam,
          scoutingColumns: cached.scoutingColumns,
          oprByTeam: cached.oprByTeam,
          epaByTeam: cached.epaByTeam,
          matchEntries: cached.matchEntries,
          playoffAlliances: cached.playoffAlliances,
          teamNames: cached.teamNames,
          lastUpdated: await LocalPrefs.lastUpdated,
        );
      }
    }
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C63FF),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _dataService,
      child: EventEntryScreen(autoLoad: true, dismissible: true),
    );
  }
}
