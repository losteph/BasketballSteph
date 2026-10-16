import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_model.dart';
import '../models/match_history_model.dart';
import '../models/team_model.dart';
import '../models/tournament_model.dart';
import 'export_helper_mobile.dart' if (dart.library.js_interop) 'export_helper_web.dart';

class StorageService {
  static const String _playersKey = 'basket_pro_players';
  static const String _matchesKey = 'basket_pro_matches';
  static const String _teamsKey = 'basket_saved_teams_list';
  static const String _tournamentsKey = 'basket_tournaments_data';

  static final List<PlayerModel> defaultPlayers = [
    PlayerModel(id: '1', name: 'Curry', role: PlayerRole.PG, stats: {'tir': 'A+', 'pas': 'A', 'dri': 'A+', 'dif': 'B', 'rim': 'C+', 'fis': 'B'}),
    PlayerModel(id: '2', name: 'Doncic', role: PlayerRole.PG, stats: {'tir': 'A', 'pas': 'A+', 'dri': 'A+', 'dif': 'B-', 'rim': 'B+', 'fis': 'A-'}),
    PlayerModel(id: '3', name: 'Jordan', role: PlayerRole.SG, stats: {'tir': 'A+', 'pas': 'A-', 'dri': 'A+', 'dif': 'A+', 'rim': 'B+', 'fis': 'A+'}),
    PlayerModel(id: '4', name: 'Bryant', role: PlayerRole.SG, stats: {'tir': 'A+', 'pas': 'B+', 'dri': 'A+', 'dif': 'A', 'rim': 'B', 'fis': 'A'}),
    PlayerModel(id: '5', name: 'LeBron', role: PlayerRole.SF, stats: {'tir': 'A-', 'pas': 'A+', 'dri': 'A', 'dif': 'A', 'rim': 'A', 'fis': 'A+'}),
    PlayerModel(id: '6', name: 'Durant', role: PlayerRole.SF, stats: {'tir': 'A+', 'pas': 'B+', 'dri': 'A', 'dif': 'B+', 'rim': 'B+', 'fis': 'A-'}),
    PlayerModel(id: '7', name: 'Giannis', role: PlayerRole.PF, stats: {'tir': 'B-', 'pas': 'B+', 'dri': 'A-', 'dif': 'A+', 'rim': 'A+', 'fis': 'A+'}),
    PlayerModel(id: '8', name: 'Duncan', role: PlayerRole.PF, stats: {'tir': 'B+', 'pas': 'B+', 'dri': 'B', 'dif': 'A+', 'rim': 'A+', 'fis': 'A'}),
    PlayerModel(id: '9', name: 'Jokic', role: PlayerRole.C, stats: {'tir': 'A', 'pas': 'A+', 'dri': 'B+', 'dif': 'B', 'rim': 'A+', 'fis': 'A'}),
    PlayerModel(id: '10', name: 'Shaq', role: PlayerRole.C, stats: {'tir': 'C-', 'pas': 'C+', 'dri': 'C+', 'dif': 'A', 'rim': 'A+', 'fis': 'A+'}),
  ];

  // ============================================================
  // DATABASE GIOCATORI
  // ============================================================
  static Future<List<PlayerModel>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playersKey);
    if (raw == null || raw.isEmpty) {
      await savePlayers(defaultPlayers);
      return List.from(defaultPlayers);
    }
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => PlayerModel.fromJson(item)).toList();
    } catch (_) {
      return List.from(defaultPlayers);
    }
  }

  static Future<void> savePlayers(List<PlayerModel> players) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = players.map((p) => p.toJson()).toList();
    await prefs.setString(_playersKey, jsonEncode(jsonList));
  }

  // ============================================================
  // STORICO PARTITE
  // ============================================================
  static Future<List<MatchHistoryModel>> loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_matchesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => MatchHistoryModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMatches(List<MatchHistoryModel> matches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_matchesKey, jsonEncode(matches.map((m) => m.toJson()).toList()));
  }

  static Future<void> saveMatch(MatchHistoryModel newMatch) async {
    final current = await loadMatches();
    current.insert(0, newMatch);
    await saveMatches(current);
  }

  static Future<void> deleteMatch(String matchId) async {
    final current = await loadMatches();
    current.removeWhere((m) => m.id == matchId);
    await saveMatches(current);
  }

  // ============================================================
  // GESTIONE SQUADRE
  // ============================================================
  static Future<List<TeamModel>> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_teamsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.map((item) => TeamModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTeams(List<TeamModel> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamsKey, jsonEncode(teams.map((t) => t.toJson()).toList()));
  }

  static Future<void> saveSingleTeam(TeamModel team) async {
    final teams = await loadTeams();
    final idx = teams.indexWhere((t) => t.id == team.id);
    if (idx != -1) {
      teams[idx] = team;
    } else {
      teams.add(team);
    }
    await saveTeams(teams);
  }

  static Future<void> deleteTeam(String teamId) async {
    final teams = await loadTeams();
    teams.removeWhere((t) => t.id == teamId);
    await saveTeams(teams);
  }

  // ============================================================
  // GESTIONE TORNEI
  // ============================================================
  static Future<List<TournamentModel>> loadTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_tournamentsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => TournamentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTournaments(List<TournamentModel> tournaments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tournamentsKey, jsonEncode(tournaments.map((t) => t.toJson()).toList()));
  }

  static Future<void> saveSingleTournament(TournamentModel tournament) async {
    final list = await loadTournaments();
    final idx = list.indexWhere((t) => t.id == tournament.id);
    if (idx != -1) {
      list[idx] = tournament;
    } else {
      list.insert(0, tournament);
    }
    await saveTournaments(list);
  }

  static Future<void> deleteTournament(String id) async {
    final list = await loadTournaments();
    list.removeWhere((t) => t.id == id);
    await saveTournaments(list);
  }

  // ============================================================
  // EXPORT / IMPORT JSON UNIVERSALE (WEB + MOBILE + DESKTOP)
  // ============================================================

  static Future<bool> exportPlayersToFile(List<PlayerModel> players) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      players.map((p) => p.toJson()).toList(),
    );
    return await saveJsonPlatform('player.json', jsonStr);
  }

  static Future<bool> exportMatchesToFile(List<MatchHistoryModel> matches) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      matches.map((m) => m.toJson()).toList(),
    );
    return await saveJsonPlatform('match.json', jsonStr);
  }

  static Future<bool> exportTeamsToFile(List<TeamModel> teams) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      teams.map((t) => t.toJson()).toList(),
    );
    return await saveJsonPlatform('teams.json', jsonStr);
  }


  static Future<bool> pickAndImportPlayersMerge() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return false;

      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return false;

      final content = utf8.decode(bytes);
      final decoded = jsonDecode(content);
      if (decoded is! List) return false;

      final newPlayers = decoded.map((item) => PlayerModel.fromJson(Map<String, dynamic>.from(item))).toList();
      final existing = await loadPlayers();

      for (final player in newPlayers) {
        if (!existing.any((e) => e.id == player.id)) {
          existing.add(player);
        }
      }
      await savePlayers(existing);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pickAndImportMatchesMerge() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return false;

      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return false;

      final content = utf8.decode(bytes);
      final decoded = jsonDecode(content);
      if (decoded is! List) return false;

      final newMatches = decoded.map((item) => MatchHistoryModel.fromJson(Map<String, dynamic>.from(item))).toList();
      final existing = await loadMatches();

      for (final match in newMatches) {
        if (!existing.any((e) => e.id == match.id)) {
          existing.add(match);
        }
      }
      existing.sort((a, b) => b.id.compareTo(a.id));
      await saveMatches(existing);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pickAndImportTeamsMerge() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return false;

      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return false;

      final content = utf8.decode(bytes);
      final decoded = jsonDecode(content);
      if (decoded is! List) return false;

      final newTeams = decoded.map((item) => TeamModel.fromJson(Map<String, dynamic>.from(item))).toList();
      final existing = await loadTeams();

      for (final team in newTeams) {
        final idx = existing.indexWhere((t) => t.id == team.id);
        if (idx != -1) {
          existing[idx] = team;
        } else {
          existing.add(team);
        }
      }
      await saveTeams(existing);
      return true;
    } catch (_) {
      return false;
    }
  }
}