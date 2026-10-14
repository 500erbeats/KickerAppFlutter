import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats_period.dart';

class AppSettings {
  final StatsPeriod statsPeriod;
  final String sheetUrl;
  final bool sheetSyncEnabled;
  final String wandLabel;
  final String treppeLabel;

  const AppSettings({
    this.statsPeriod = StatsPeriod.quarter,
    this.sheetUrl = '',
    this.sheetSyncEnabled = false,
    this.wandLabel = '',
    this.treppeLabel = '',
  });

  String get effectiveWandLabel => wandLabel.trim().isEmpty ? 'Wandseite' : wandLabel.trim();
  String get effectiveTreppeLabel => treppeLabel.trim().isEmpty ? 'Treppenseite' : treppeLabel.trim();

  AppSettings copyWith({
    StatsPeriod? statsPeriod,
    String? sheetUrl,
    bool? sheetSyncEnabled,
    String? wandLabel,
    String? treppeLabel,
  }) =>
      AppSettings(
        statsPeriod: statsPeriod ?? this.statsPeriod,
        sheetUrl: sheetUrl ?? this.sheetUrl,
        sheetSyncEnabled: sheetSyncEnabled ?? this.sheetSyncEnabled,
        wandLabel: wandLabel ?? this.wandLabel,
        treppeLabel: treppeLabel ?? this.treppeLabel,
      );
}

class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kPeriod = 'statsPeriod';
  static const _kUrl = 'sheetWebAppURL';
  static const _kEnabled = 'sheetSyncEnabled';
  static const _kWand = 'sideWandLabel';
  static const _kTreppe = 'sideTreppeLabel';
  static const _kLastDraw = 'lastDrawData';

  AppSettings load() => AppSettings(
        statsPeriod: StatsPeriod.fromName(_prefs.getString(_kPeriod) ?? 'quarter'),
        sheetUrl: _prefs.getString(_kUrl) ?? '',
        sheetSyncEnabled: _prefs.getBool(_kEnabled) ?? false,
        wandLabel: _prefs.getString(_kWand) ?? '',
        treppeLabel: _prefs.getString(_kTreppe) ?? '',
      );

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kPeriod, s.statsPeriod.name);
    await _prefs.setString(_kUrl, s.sheetUrl);
    await _prefs.setBool(_kEnabled, s.sheetSyncEnabled);
    await _prefs.setString(_kWand, s.wandLabel);
    await _prefs.setString(_kTreppe, s.treppeLabel);
  }

  String? loadLastDrawJson() => _prefs.getString(_kLastDraw);

  Future<void> saveLastDrawJson(String? json) async {
    if (json == null) {
      await _prefs.remove(_kLastDraw);
    } else {
      await _prefs.setString(_kLastDraw, json);
    }
  }
}
