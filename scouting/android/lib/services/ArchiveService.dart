import 'dart:convert';
import 'package:hive/hive.dart';
import 'DataBase.dart';

/// ArchiveService — Season-level data archival for FRC game changeovers.
///
/// When the upstream fork pushes a new game (typically each January),
/// call [archiveCurrentSeason] BEFORE syncing to snapshot all game-specific
/// data into a year-keyed Hive box (e.g. "archive_2026").
///
/// **Affected modules:**
///   - Match Scouting   (matchData, match, responces)
///   - Pit Scouting     (pitData)
///   - Dashboard        (scoutingItems)
///   - Qualitative      (qualitative)
///
/// **Unaffected modules:**
///   - QR Scanner       (game-agnostic — just ingests data)
///   - Settings/prefs   (userData, settings — persist across seasons)
///
/// After archiving you can safely clear the active boxes and pull the new
/// game templates from upstream. Old seasons stay accessible in read-only
/// mode via [getArchivedSeasons] / [loadArchivedSeason].
class ArchiveService {
  // ── Box names that contain game-specific data ──────────────────────
  static const List<String> _gameBoxes = [
    'matchData',
    'match',
    'pitData',
    'scoutingItems',
    'qualitative',
    'responces',
  ];

  // ── Archive a season ───────────────────────────────────────────────

  /// Snapshots every game-specific Hive box into `archive_<seasonKey>`.
  ///
  /// [seasonKey] is a label like "2026_rebuilt" or just the year "2026".
  /// Set [clearAfterArchive] to `true` to wipe the active boxes afterwards
  /// so the app is clean for the incoming game templates.
  static Future<bool> archiveCurrentSeason({
    required String seasonKey,
    bool clearAfterArchive = false,
  }) async {
    try {
      final archiveBoxName = 'archive_$seasonKey';

      // Open (or create) the archive box
      final archiveBox = await Hive.openBox(archiveBoxName);

      // Snapshot each game box
      for (final boxName in _gameBoxes) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          final Map<String, dynamic> snapshot = {};
          for (final key in box.keys) {
            snapshot[key.toString()] = box.get(key);
          }
          await archiveBox.put(boxName, jsonEncode(snapshot));
        }
      }

      // Stamp metadata
      await archiveBox.put('_meta', jsonEncode({
        'seasonKey': seasonKey,
        'archivedAt': DateTime.now().toIso8601String(),
        'eventKey': Hive.box('userData').get('eventKey', defaultValue: ''),
      }));

      // Register in the season index
      await _registerSeason(seasonKey);

      // Optionally wipe active boxes
      if (clearAfterArchive) {
        await clearActiveSeasonData();
      }

      return true;
    } catch (e) {
      print('[ArchiveService] Failed to archive season "$seasonKey": $e');
      return false;
    }
  }

  // ── Clear active season data ───────────────────────────────────────

  /// Clears all game-specific boxes without touching settings or user prefs.
  static Future<void> clearActiveSeasonData() async {
    for (final boxName in _gameBoxes) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
    // Also clear the in-memory static stores
    MatchDataBase.ClearData();
    PitDataBase.ClearData();
    QualitativeDataBase.ClearData();
  }

  // ── List archived seasons ──────────────────────────────────────────

  /// Returns a list of archived season keys (e.g. ["2025", "2026_rebuilt"]).
  static Future<List<ArchivedSeason>> getArchivedSeasons() async {
    final List<ArchivedSeason> seasons = [];

    // Scan for any Hive box files whose names start with "archive_"
    // For now, we keep a registry in the settings box.
    final settingsBox = Hive.box('settings');
    final List<dynamic> registry =
        settingsBox.get('archivedSeasons', defaultValue: <dynamic>[]);

    for (final key in registry) {
      try {
        final box = await Hive.openBox('archive_$key');
        final metaRaw = box.get('_meta');
        Map<String, dynamic> meta = {};
        if (metaRaw != null) {
          meta = jsonDecode(metaRaw);
        }
        seasons.add(ArchivedSeason(
          seasonKey: key.toString(),
          archivedAt: meta['archivedAt'] ?? 'Unknown',
          eventKey: meta['eventKey'] ?? '',
        ));
      } catch (_) {
        // Box doesn't exist anymore — skip
      }
    }

    return seasons;
  }

  /// Registers a season key in the settings-box registry.
  /// Called automatically by [archiveCurrentSeason].
  static Future<void> _registerSeason(String seasonKey) async {
    final settingsBox = Hive.box('settings');
    final List<dynamic> registry =
        List.from(settingsBox.get('archivedSeasons', defaultValue: <dynamic>[]));
    if (!registry.contains(seasonKey)) {
      registry.add(seasonKey);
      await settingsBox.put('archivedSeasons', registry);
    }
  }

  // ── Load an archived season (read-only browsing) ───────────────────

  /// Loads an archived season's data into memory for read-only viewing.
  /// Returns the raw map of { boxName: { key: value } }.
  ///
  /// TODO: Wire this into a "Past Seasons" UI screen when needed.
  static Future<Map<String, dynamic>> loadArchivedSeason(
      String seasonKey) async {
    final archiveBox = await Hive.openBox('archive_$seasonKey');
    final Map<String, dynamic> data = {};

    for (final boxName in _gameBoxes) {
      final raw = archiveBox.get(boxName);
      if (raw != null) {
        data[boxName] = jsonDecode(raw);
      }
    }

    return data;
  }

  // ── Delete an archived season ──────────────────────────────────────

  /// Permanently deletes an archived season. This cannot be undone.
  static Future<void> deleteArchivedSeason(String seasonKey) async {
    try {
      final box = await Hive.openBox('archive_$seasonKey');
      await box.deleteFromDisk();

      // Remove from registry
      final settingsBox = Hive.box('settings');
      final List<dynamic> registry = List.from(
          settingsBox.get('archivedSeasons', defaultValue: <dynamic>[]));
      registry.remove(seasonKey);
      await settingsBox.put('archivedSeasons', registry);
    } catch (e) {
      print('[ArchiveService] Failed to delete archive "$seasonKey": $e');
    }
  }
}

/// Metadata for a single archived season.
class ArchivedSeason {
  final String seasonKey;
  final String archivedAt;
  final String eventKey;

  ArchivedSeason({
    required this.seasonKey,
    required this.archivedAt,
    required this.eventKey,
  });

  @override
  String toString() =>
      'ArchivedSeason($seasonKey, archived: $archivedAt, event: $eventKey)';
}
