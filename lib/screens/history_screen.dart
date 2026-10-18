// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import '../models/match_history_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/tournament_model.dart';
import '../models/match_roster_player.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final Function(
    List<MatchRosterPlayer> homeRoster,
    List<MatchRosterPlayer> awayRoster,
    String homeName,
    String awayName,
    Color homeColor,
    Color awayColor, [
    String? tournamentId,
  ])? onLoadTournamentMatch;

  const HistoryScreen({super.key, this.onLoadTournamentMatch});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class LeagueBasketRow {
  final String teamId;
  final String teamName;
  final int teamColorValue;
  int played = 0;
  int won = 0;
  int lost = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  LeagueBasketRow({
    required this.teamId,
    required this.teamName,
    required this.teamColorValue,
  });

  int get points => (won * 2);
  int get diff => pointsFor - pointsAgainst;
}

class HistoryScreenState extends State<HistoryScreen> {
  List<MatchHistoryModel> _matches = [];
  List<PlayerModel> _dbPlayers = [];
  List<TeamModel> _allTeams = [];
  List<TournamentModel> _tournaments = [];
  bool _isLoading = true;

  String _selectedViewId = 'ALL';
  int _activeSubTab = 0;

  TeamModel? _selectedHomeTeam;
  TeamModel? _selectedAwayTeam;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() => _isLoading = true);
    final matches = await StorageService.loadMatches();
    final players = await StorageService.loadPlayers();
    final teams = await StorageService.loadTeams();
    final tournaments = await StorageService.loadTournaments();

    if (mounted) {
      setState(() {
        _matches = matches;
        _dbPlayers = players;
        _allTeams = teams;
        _tournaments = tournaments;

        if (_selectedViewId != 'ALL' &&
            _selectedViewId != 'FRIENDLY' &&
            !_tournaments.any((t) => t.id == _selectedViewId)) {
          _selectedViewId = 'ALL';
          _activeSubTab = 0;
        }
        _isLoading = false;
      });
    }
  }

  TournamentModel? get _currentTournament {
    if (_selectedViewId == 'ALL' || _selectedViewId == 'FRIENDLY') return null;
    try {
      return _tournaments.firstWhere((t) => t.id == _selectedViewId);
    } catch (_) {
      return null;
    }
  }

  List<MatchHistoryModel> get _filteredMatches {
    if (_selectedViewId == 'ALL') return _matches;
    if (_selectedViewId == 'FRIENDLY') {
      return _matches.where((m) => m.tournamentId == null || m.tournamentId!.isEmpty).toList();
    }
    return _matches.where((m) => m.tournamentId == _selectedViewId).toList();
  }

  String _getTeamEmoji(int colorValue) {
    if (colorValue == const Color(0xFF3B82F6).toARGB32()) return '🔵';
    if (colorValue == const Color(0xFFEF4444).toARGB32()) return '🔴';
    if (colorValue == const Color(0xFF10B981).toARGB32()) return '🟢';
    if (colorValue == const Color(0xFFEAB308).toARGB32()) return '🟡';
    if (colorValue == const Color(0xFFF97316).toARGB32()) return '🟠';
    if (colorValue == const Color(0xFF8B5CF6).toARGB32()) return '🟣';
    if (colorValue == const Color(0xFF1E293B).toARGB32()) return '⚫';
    if (colorValue == const Color(0xFFF8FAFC).toARGB32()) return '⚪';
    return '🏀';
  }

  // Riconosce il quarto o l'overtime per generare il divisore in cronaca
  String _getPeriodHeader(String minute) {
    final m = minute.toUpperCase();
    if (m.contains('1°OT') || m.contains('1° OT')) return '1° OVERTIME';
    if (m.contains('2°OT') || m.contains('2° OT')) return '2° OVERTIME';
    if (m.contains('1°Q') || m.contains('1° Q')) return '1° QUARTO';
    if (m.contains('2°Q') || m.contains('2° Q')) return '2° QUARTO';
    if (m.contains('3°Q') || m.contains('3° Q')) return '3° QUARTO';
    if (m.contains('4°Q') || m.contains('4° Q')) return '4° QUARTO';
    return '';
  }

  String _calcTeamAverage(List<Map<String, dynamic>> teamRatings) {
    final validScores = teamRatings
        .where((r) => r['score'] != 'SV' && r['numScore'] != null && (r['numScore'] as double) > 0)
        .map((r) => r['numScore'] as double)
        .toList();

    if (validScores.isEmpty) return 'N.D.';
    final avg = validScores.reduce((a, b) => a + b) / validScores.length;
    return avg.toStringAsFixed(1);
  }

  Widget _buildTeamAvgBadge(String avg, Color teamColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: teamColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 10, color: Color(0xFFEAB308)),
          const SizedBox(width: 3),
          Text(
            avg,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<LeagueBasketRow> _calculateLeagueTable(TournamentModel tournament) {
    final Map<String, LeagueBasketRow> tableMap = {};

    for (final tId in tournament.teamIds) {
      final teamObj = _allTeams.where((x) => x.id == tId).firstOrNull;
      if (teamObj != null) {
        tableMap[teamObj.name.trim().toLowerCase()] = LeagueBasketRow(
          teamId: teamObj.id,
          teamName: teamObj.name,
          teamColorValue: teamObj.colorValue,
        );
      }
    }

    final tourMatches = _filteredMatches;
    for (final m in tourMatches) {
      final hKey = m.homeName.trim().toLowerCase();
      final aKey = m.awayName.trim().toLowerCase();

      tableMap.putIfAbsent(
        hKey,
        () => LeagueBasketRow(teamId: hKey, teamName: m.homeName, teamColorValue: m.homeColorValue),
      );
      tableMap.putIfAbsent(
        aKey,
        () => LeagueBasketRow(teamId: aKey, teamName: m.awayName, teamColorValue: m.awayColorValue),
      );

      final hRow = tableMap[hKey]!;
      final aRow = tableMap[aKey]!;

      hRow.played++;
      aRow.played++;

      hRow.pointsFor += m.homeScore;
      hRow.pointsAgainst += m.awayScore;

      aRow.pointsFor += m.awayScore;
      aRow.pointsAgainst += m.homeScore;

      if (m.homeScore > m.awayScore) {
        hRow.won++;
        aRow.lost++;
      } else {
        aRow.won++;
        hRow.lost++;
      }
    }

    final rows = tableMap.values.toList();
    rows.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);

      int h2hA = 0;
      int h2hB = 0;
      for (final m in tourMatches) {
        final h = m.homeName.trim().toLowerCase();
        final aw = m.awayName.trim().toLowerCase();
        final nameA = a.teamName.trim().toLowerCase();
        final nameB = b.teamName.trim().toLowerCase();

        if (h == nameA && aw == nameB) {
          if (m.homeScore > m.awayScore) {
            h2hA += 2;
          } else {
            h2hB += 2;
          }
        } else if (h == nameB && aw == nameA) {
          if (m.homeScore > m.awayScore) {
            h2hB += 2;
          } else {
            h2hA += 2;
          }
        }
      }
      if (h2hA != h2hB) return h2hB.compareTo(h2hA);

      if (b.diff != a.diff) return b.diff.compareTo(a.diff);
      if (b.pointsFor != a.pointsFor) return b.pointsFor.compareTo(a.pointsFor);

      return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
    });

    return rows;
  }

  List<Map<String, dynamic>> _getScorersRanking() {
    final Map<String, Map<String, dynamic>> stats = {};
    final targetMatches = _filteredMatches;

    if (_selectedViewId == 'ALL' || _selectedViewId == 'FRIENDLY') {
      for (var p in _dbPlayers) {
        stats[p.name] = {'name': p.name, 'points': 0, 'rebounds': 0, 'assists': 0};
      }
    } else if (_currentTournament != null) {
      final enrolledTeams = _allTeams.where((t) => _currentTournament!.teamIds.contains(t.id));
      for (final team in enrolledTeams) {
        for (final entry in team.roster) {
          final dbP = _dbPlayers.where((p) => p.id == entry.playerId).firstOrNull;
          if (dbP != null) {
            stats[dbP.name] = {'name': dbP.name, 'points': 0, 'rebounds': 0, 'assists': 0};
          }
        }
      }
    }

    for (var m in targetMatches) {
      for (var e in m.events) {
        final pName = _getPlayerNameFromId(m, e.playerId);
        if (pName != null) {
          stats.putIfAbsent(pName, () => {'name': pName, 'points': 0, 'rebounds': 0, 'assists': 0});
          if (e.pts > 0) {
            stats[pName]!['points'] += e.pts;
          }
          if (e.type == 'REBOUND') {
            stats[pName]!['rebounds']++;
          }
        }

        if (e.sub.contains('Assist:')) {
          final match = RegExp(r'Assist:\s*#\d+\s+([^•\)]+)').firstMatch(e.sub);
          if (match != null) {
            final aName = match.group(1)!.trim();
            stats.putIfAbsent(aName, () => {'name': aName, 'points': 0, 'rebounds': 0, 'assists': 0});
            stats[aName]!['assists']++;
          }
        }
      }
    }

    final list = stats.values.toList();
    list.sort((a, b) {
      int pCmp = (b['points'] as int).compareTo(a['points'] as int);
      if (pCmp != 0) return pCmp;
      int rCmp = (b['rebounds'] as int).compareTo(a['rebounds'] as int);
      if (rCmp != 0) return rCmp;
      int aCmp = (b['assists'] as int).compareTo(a['assists'] as int);
      if (aCmp != 0) return aCmp;
      return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
    });

    return list;
  }

  String? _getPlayerNameFromId(MatchHistoryModel m, String? id) {
    if (id == null) return null;
    final allPlayers = [...m.homeRoster, ...m.awayRoster];
    try {
      return allPlayers.firstWhere((p) => p.dbId == id).name;
    } catch (_) {
      return null;
    }
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Gestione Storico Partite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Scarica o carica il file JSON dello storico partite. L\'importazione aggiungerà le partite non ancora presenti.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final success = await StorageService.exportMatchesToFile(_matches);
              if (mounted && success) {
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File storico partite esportato!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Esporta JSON'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await StorageService.pickAndImportMatchesMerge();
              if (success) {
                reload();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partite caricate con successo!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              }
            },
            icon: const Icon(Icons.file_upload_outlined, size: 16),
            label: const Text('Importa JSON'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateMatchRatings(MatchHistoryModel m) {
    final Map<String, List<Map<String, dynamic>>> res = {'home': [], 'away': []};
    final hWon = m.homeScore > m.awayScore;
    final aWon = m.awayScore > m.homeScore;

    double maxScore = 0.0;
    Map<String, dynamic>? currentMvp;
    bool isDrawMvp = false;

    for (final team in ['home', 'away']) {
      final isHome = team == 'home';
      final won = isHome ? hWon : aWon;
      final lost = isHome ? aWon : hWon;
      final list = isHome ? m.homeRoster : m.awayRoster;

      for (final p in list) {
        int pts1 = 0, pts2 = 0, pts3 = 0, assists = 0, rebounds = 0, goodPlays = 0, fouls = 0, turnovers = 0;

        for (final e in m.events) {
          if (e.playerId == p.dbId) {
            if (e.type == 'SCORE_1PT') pts1++;
            if (e.type == 'SCORE_2PT') pts2++;
            if (e.type == 'SCORE_3PT') pts3++;
            if (e.type == 'FOUL') fouls++;
            if (e.type == 'REBOUND') rebounds++;
            if (e.type == 'GOOD_PLAY') goodPlays++;
            if (e.type == 'TURNOVER') turnovers++;
          }
          if (e.sub.contains('Assist: #${p.num} ${p.name}')) assists++;
        }

        final int totalPoints = (pts3 * 3) + (pts2 * 2) + pts1;
        final bool hasAction = totalPoints > 0 || assists > 0;
        final bool playedEnough = p.playedSeconds >= 180;

        if (!hasAction && !playedEnough) {
          res[team]!.add({'id': p.dbId, 'num': p.num, 'name': p.name, 'role': p.role.name, 'score': 'SV', 'numScore': 0.0, 'inField': p.inField});
          continue;
        }

        double score = 6.0;
        if (won) score += 0.2;
        if (lost) score -= 0.1;

        score += (pts3 * 0.5);
        score += (pts2 * 0.3);
        score += (pts1 * 0.1);
        score += (assists * 0.2);
        score += (goodPlays * 0.1);
        score += (rebounds * 0.2);
        score -= (turnovers * 0.2);
        score -= (fouls * 0.4);

        score = score.clamp(1.0, 9.9);

        final pData = {
          'id': p.dbId,
          'num': p.num,
          'name': p.name,
          'role': p.role.name,
          'score': score.toStringAsFixed(1),
          'numScore': score,
          'isWinner': won,
          'totalPoints': totalPoints,
          'assists': assists,
          'malusCount': fouls + turnovers,
          'playedSeconds': p.playedSeconds,
          'inField': p.inField,
        };

        res[team]!.add(pData);

        if (score > maxScore) {
          maxScore = score;
          currentMvp = pData;
          isDrawMvp = false;
        } else if (score == maxScore && currentMvp != null) {
          final bool pWinner = pData['isWinner'] as bool;
          final bool mvpWinner = currentMvp['isWinner'] as bool;
          if (pWinner && !mvpWinner) {
            currentMvp = pData;
            isDrawMvp = false;
          } else if (pWinner == mvpWinner) {
            if ((pData['totalPoints'] as int) > (currentMvp['totalPoints'] as int)) {
              currentMvp = pData;
              isDrawMvp = false;
            } else if ((pData['totalPoints'] as int) == (currentMvp['totalPoints'] as int)) {
              if ((pData['assists'] as int) > (currentMvp['assists'] as int)) {
                currentMvp = pData;
                isDrawMvp = false;
              } else {
                isDrawMvp = true;
              }
            }
          }
        }
      }
    }

    if (currentMvp != null && !isDrawMvp) {
      currentMvp['isMvp'] = true;
    }
    return res;
  }

  void _openTournamentModal([TournamentModel? existing]) async {
    final freshTeams = await StorageService.loadTeams();
    if (mounted) setState(() => _allTeams = freshTeams);
    if (!mounted) return;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final Set<String> selectedTeamIds = Set<String>.from(existing?.teamIds ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? '🏆 Nuovo Torneo Basket' : '✏️ Modifica Torneo',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome Torneo Basket',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('SQUADRE ISCRITTE (${selectedTeamIds.length}):', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allTeams.length,
                      itemBuilder: (c, i) {
                        final t = _allTeams[i];
                        final isSel = selectedTeamIds.contains(t.id);
                        return CheckboxListTile(
                          value: isSel,
                          activeColor: const Color(0xFFF97316),
                          title: Row(
                            children: [
                              Container(width: 8, height: 16, decoration: BoxDecoration(color: Color(t.colorValue), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          onChanged: (val) {
                            setMState(() {
                              if (val == true) {
                                selectedTeamIds.add(t.id);
                              } else {
                                selectedTeamIds.remove(t.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      if (existing != null) ...[
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (d) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: const Text('Elimina Torneo', style: TextStyle(color: Colors.white)),
                                content: Text('Vuoi eliminare "${existing.name}"?', style: const TextStyle(color: Color(0xFF94A3B8))),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annulla')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const Text('Elimina', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await StorageService.deleteTournament(existing.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                              setState(() => _selectedViewId = 'ALL');
                              reload();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annulla', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            final saved = TournamentModel(
                              id: existing?.id ?? 'tour_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              teamIds: selectedTeamIds.toList(),
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );
                            await StorageService.saveSingleTournament(saved);
                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() => _selectedViewId = saved.id);
                            reload();
                          },
                          child: const Text('Salva Torneo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMatchDetail(MatchHistoryModel m) {
    final ratings = _calculateMatchRatings(m);
    final homeAvg = _calcTeamAverage(ratings['home']!);
    final awayAvg = _calcTeamAverage(ratings['away']!);
    final hEmoji = _getTeamEmoji(m.homeColorValue);
    final aEmoji = _getTeamEmoji(m.awayColorValue);

    const salienti = ['SCORE_1PT', 'SCORE_2PT', 'SCORE_3PT', 'FOUL', 'SUB'];
final filteredEvents = m.events.where((e) => salienti.contains(e.type)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.date, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ordine: Nome Logo Risultato Logo Nome
                      Expanded(
                        child: Text(
                          '${m.homeName} $hEmoji',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                      Text('${m.homeScore} - ${m.awayScore}', style: const TextStyle(color: Color(0xFFF97316), fontSize: 24, fontWeight: FontWeight.w900)),
                      Expanded(
                        child: Text(
                          '$aEmoji ${m.awayName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                  child: const TabBar(
                    indicatorColor: Color(0xFFF97316),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Color(0xFFF97316),
                    unselectedLabelColor: Color(0xFF94A3B8),
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: [
                      Tab(text: '🏀 Voti & MVP'),
                      Tab(text: '📜 Cronaca'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: VOTI & MVP CON MEDIA SQUADRA
                      ListView(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$hEmoji ${m.homeName.toUpperCase()}', style: TextStyle(color: Color(m.homeColorValue), fontWeight: FontWeight.w900, fontSize: 13)),
                              _buildTeamAvgBadge(homeAvg, Color(m.homeColorValue)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ..._buildPagelleListWithBench(ratings['home']!),
                          const Divider(color: Color(0xFF334155), height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$aEmoji ${m.awayName.toUpperCase()}', style: TextStyle(color: Color(m.awayColorValue), fontWeight: FontWeight.w900, fontSize: 13)),
                              _buildTeamAvgBadge(awayAvg, Color(m.awayColorValue)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ..._buildPagelleListWithBench(ratings['away']!),
                        ],
                      ),

                      // TAB 2: CRONACA CON BANNER QUARTI E LATO CASA/OSPITI
                      filteredEvents.isEmpty
                          ? const Center(child: Text('Nessun evento registrato.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)))
                          : Builder(
                              builder: (context) {
                                final chronologicalEvents = filteredEvents.reversed.toList();
                                return ListView.builder(
                                  itemCount: chronologicalEvents.length,
                                  itemBuilder: (c, idx) {
                                    final e = chronologicalEvents[idx];

                                    // Rimuove il prefisso del quarto (es. "1°Q 04:12" -> "04:12")
                                    final String cleanTime = e.minute
                                        .replaceAll(RegExp(r'^(1°Q|2°Q|3°Q|4°Q|1°OT|2°OT)\s*', caseSensitive: false), '')
                                        .trim();

                                    final currentPeriod = _getPeriodHeader(e.minute);
                                    final prevPeriod = idx > 0 ? _getPeriodHeader(chronologicalEvents[idx - 1].minute) : '';
                                    final bool showDivider = currentPeriod.isNotEmpty && currentPeriod != prevPeriod;

                                    final bool isAway = e.team == 'away';
                                    final String cleanSub = e.sub
                                        .replaceAll(RegExp(r'Squadra:\s*[^•\n]+(•\s*)?', caseSensitive: false), '')
                                        .trim();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (showDivider)
                                          Padding(
                                            padding: EdgeInsets.only(top: idx == 0 ? 4 : 14, bottom: 8),
                                            child: Row(
                                              children: [
                                                const Expanded(child: Divider(color: Color(0xFF334155), thickness: 1)),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Text(
                                                    currentPeriod,
                                                    style: const TextStyle(
                                                      color: Color(0xFFF97316),
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 10,
                                                      letterSpacing: 1.1,
                                                    ),
                                                  ),
                                                ),
                                                const Expanded(child: Divider(color: Color(0xFF334155), thickness: 1)),
                                              ],
                                            ),
                                          ),
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E293B),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            textDirection: isAway ? TextDirection.rtl : TextDirection.ltr,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  cleanTime,
                                                  style: const TextStyle(
                                                    color: Color(0xFFF97316),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    fontFamily: 'Courier',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  textDirection: isAway ? TextDirection.rtl : TextDirection.ltr,
                                                  children: [
                                                    Text(
                                                      e.title,
                                                      textAlign: isAway ? TextAlign.right : TextAlign.left,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    if (cleanSub.isNotEmpty)
                                                      Text(
                                                        cleanSub,
                                                        textAlign: isAway ? TextAlign.right : TextAlign.left,
                                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155))),
                        child: const Text('Chiudi', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Elimina', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('Elimina Partita', style: TextStyle(color: Colors.white)),
                              content: Text('Vuoi eliminare definitivamente "${m.homeName} vs ${m.awayName}"?', style: const TextStyle(color: Color(0xFF94A3B8))),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annulla')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                  onPressed: () => Navigator.pop(d, true),
                                  child: const Text('Elimina', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await StorageService.deleteMatch(m.id);
                            reload();
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBenchDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Color(0xFF334155), thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'PANCHINA',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFF334155), thickness: 1)),
        ],
      ),
    );
  }

  List<Widget> _buildPagelleListWithBench(List<Map<String, dynamic>> rawList) {
    final list = List<Map<String, dynamic>>.from(rawList);
    list.sort((a, b) {
      final aSt = a['inField'] != false ? 1 : 0;
      final bSt = b['inField'] != false ? 1 : 0;
      return bSt.compareTo(aSt);
    });

    final List<Widget> widgets = [];
    bool benchDividerShown = false;

    for (final r in list) {
      if (r['inField'] == false && !benchDividerShown) {
        widgets.add(_buildBenchDivider());
        benchDividerShown = true;
      }
      widgets.add(_buildPagellaRow(r));
    }
    return widgets;
  }


  Widget _buildPagellaRow(Map<String, dynamic> r) {
    final isMvp = r['isMvp'] == true;
    final isSV = r['score'] == 'SV';
    final double scoreVal = double.tryParse(r['score']?.toString() ?? '') ?? 0.0;

    Color badgeColor;
    if (isMvp) {
      badgeColor = const Color(0xFF0044FF);
    } else if (isSV) {
      badgeColor = const Color(0xFF334155);
    } else if (scoreVal >= 6.8) {
      badgeColor = const Color(0xFF0A7227);
    } else if (scoreVal >= 5.8) {
      badgeColor = const Color(0xFFD97706);
    } else {
      badgeColor = const Color(0xFFD50000);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('#${r['num']} ${r['name']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              if (isMvp)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFF0044FF), borderRadius: BorderRadius.circular(4)),
                  child: const Text('MVP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
            child: Text(r['score'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTournament = _currentTournament != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: const Color(0xFF111827),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedViewId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('🌐 Tutte le Partite')),
                    const DropdownMenuItem(value: 'FRIENDLY', child: Text('🏀 Solo Amichevoli')),
                    ..._tournaments.map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text('🏆 ${t.name.toUpperCase()}', style: const TextStyle(color: Color(0xFFF97316))),
                    )),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() { _selectedViewId = val; _activeSubTab = 0; });
                  },
                ),
              ),
              if (isTournament) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Color(0xFFF97316), size: 22),
                  tooltip: 'Modifica / Elimina Torneo',
                  onPressed: () => _openTournamentModal(_currentTournament),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.emoji_events, color: Color(0xFFF97316)),
                onPressed: () => _openTournamentModal(),
                tooltip: 'Nuovo Torneo',
              ),
              IconButton(
                icon: const Icon(Icons.cloud_sync, color: Color(0xFF94A3B8)),
                onPressed: _showBackupDialog,
                tooltip: 'Backup Match',
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0xFF090D16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isTournament
                  ? [
                      _subTabPill(0, 'CLASSIFICA'),
                      _subTabPill(1, 'PARTITE'),
                      _subTabPill(2, 'STATS'),
                      _subTabPill(3, 'SQUADRE'),
                    ]
                  : [
                      _subTabPill(0, 'PARTITE'),
                      _subTabPill(1, 'STATS'),
                    ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
              : _buildCurrentSubTabContent(isTournament),
        ),
      ],
    );
  }

  Widget _subTabPill(int index, String label) {
    final active = _activeSubTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _activeSubTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? const Color(0xFFF97316) : Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFF97316) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubTabContent(bool isTournament) {
    if (!isTournament) {
      return _activeSubTab == 0 ? _buildMatchesTab() : _buildScorersTab();
    } else {
      switch (_activeSubTab) {
        case 0: return _buildLeagueTableTab(_currentTournament!);
        case 1: return _buildMatchesTab();
        case 2: return _buildScorersTab();
        case 3: return _buildTournamentTeamsTab(_currentTournament!);
        default: return _buildLeagueTableTab(_currentTournament!);
      }
    }
  }

  Widget _buildLeagueTableTab(TournamentModel tournament) {
    final rows = _calculateLeagueTable(tournament);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CLASSIFICA BASKET', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(11))),
                  child: const Row(
                    children: [
                      SizedBox(width: 24, child: Text('POS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('SQUADRA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold))),
                      SizedBox(width: 28, child: Text('PT', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF97316), fontSize: 10, fontWeight: FontWeight.bold))),
                      SizedBox(width: 24, child: Text('G', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10))),
                      SizedBox(width: 24, child: Text('V', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10))),
                      SizedBox(width: 24, child: Text('P', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10))),
                      SizedBox(width: 30, child: Text('PF', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10))),
                      SizedBox(width: 30, child: Text('PS', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10))),
                      SizedBox(width: 30, child: Text('DC', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10))),
                    ],
                  ),
                ),
                ...rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E293B)))),
                    child: Row(
                      children: [
                        SizedBox(width: 24, child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 8, height: 16, decoration: BoxDecoration(color: Color(r.teamColorValue), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(r.teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 28, child: Text('${r.points}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w900, fontSize: 13))),
                        SizedBox(width: 24, child: Text('${r.played}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
                        SizedBox(width: 24, child: Text('${r.won}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                        SizedBox(width: 24, child: Text('${r.lost}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                        SizedBox(width: 30, child: Text('${r.pointsFor}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                        SizedBox(width: 30, child: Text('${r.pointsAgainst}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                        SizedBox(width: 30, child: Text('${r.diff}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(10)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Legenda Basket:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 4),
                Text('• Vittoria (V): +2 pt', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text('• Sconfitta (P): 0 pt', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text('Criteri in caso di parità di PT (Ex-Aequo):', style: TextStyle(color: Color.fromARGB(255, 188, 195, 205), fontSize: 11, fontWeight: FontWeight.bold)),
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Esito dello Scontro Diretto', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      Text('2. Miglior Differenza Canestri (DC: PF - PS)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      Text('3. Maggior numero di Punti Segnati Totali (PF)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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

  Widget _buildMatchesTab() {
    final list = _filteredMatches;
    if (list.isEmpty) {
      return const Center(child: Text('Nessuna partita registrata.', style: TextStyle(color: Color(0xFF94A3B8))));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final m = list[i];
        final hEmoji = _getTeamEmoji(m.homeColorValue);
        final aEmoji = _getTeamEmoji(m.awayColorValue);

        return InkWell(
          onTap: () => _openMatchDetail(m),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    Text('${m.events.length} Eventi', style: const TextStyle(fontSize: 10, color: Color(0xFFF97316), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                // Ordine: Nome Logo Risultato Logo Nome
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${m.homeName} $hEmoji',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${m.homeScore} - ${m.awayScore}',
                        style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$aEmoji ${m.awayName}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScorersTab() {
    final list = _getScorersRanking();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: const Color(0xFF111827),
          child: const Row(
            children: [
              SizedBox(width: 30, child: Text('POS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(child: Text('GIOCATORE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))),
              SizedBox(width: 40, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF97316), fontSize: 11, fontWeight: FontWeight.bold))),
              SizedBox(width: 40, child: Text('RIM', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold))),
              SizedBox(width: 40, child: Text('ASS', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Nessun giocatore registrato.', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final s = list[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E293B)))),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                          Expanded(child: Text(s['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                          SizedBox(width: 40, child: Text('${s['points']}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w900, fontSize: 15))),
                          SizedBox(width: 40, child: Text('${s['rebounds']}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 13))),
                          SizedBox(width: 40, child: Text('${s['assists']}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13))),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTournamentTeamsTab(TournamentModel tournament) {
    final enrolledTeams = _allTeams.where((t) => tournament.teamIds.contains(t.id)).toList();
    final canLaunch = _selectedHomeTeam != null && _selectedAwayTeam != null;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (canLaunch)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                onPressed: () {
                  final h = _convertTeamToRoster(_selectedHomeTeam!);
                  final a = _convertTeamToRoster(_selectedAwayTeam!);
                  widget.onLoadTournamentMatch?.call(
                    h,
                    a,
                    _selectedHomeTeam!.name,
                    _selectedAwayTeam!.name,
                    Color(_selectedHomeTeam!.colorValue),
                    Color(_selectedAwayTeam!.colorValue),
                    tournament.id,
                  );
                },
                icon: const Icon(Icons.sports_basketball, color: Colors.white),
                label: Text('GIOCA: ${_selectedHomeTeam!.name} VS ${_selectedAwayTeam!.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          Expanded(
            child: enrolledTeams.isEmpty
                ? const Center(
                    child: Text(
                      'Nessuna squadra iscritta.\nUsa il pulsante in basso per aggiungerle!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    itemCount: enrolledTeams.length,
                    itemBuilder: (ctx, i) {
                      final t = enrolledTeams[i];
                      final isHome = _selectedHomeTeam?.id == t.id;
                      final isAway = _selectedAwayTeam?.id == t.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isHome) {
                              _selectedHomeTeam = null;
                            } else if (isAway) {
                              _selectedAwayTeam = null;
                            } else if (_selectedHomeTeam == null) {
                              _selectedHomeTeam = t;
                            } else {
                              _selectedAwayTeam = t;
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: (isHome || isAway) ? const Color(0xFFF97316) : const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(width: 8, height: 16, decoration: BoxDecoration(color: Color(t.colorValue), borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 8),
                                  Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (isHome) const Text('[CASA]', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                              if (isAway) const Text('[OSPITI]', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _openTournamentModal(tournament),
              icon: const Icon(Icons.group_add, color: Colors.white, size: 18),
              label: const Text('Gestisci Squadre Iscritte / Elimina Torneo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  List<MatchRosterPlayer> _convertTeamToRoster(TeamModel team) {
    return team.roster.map((e) {
      final dbP = _dbPlayers.firstWhere((p) => p.id == e.playerId, orElse: () => PlayerModel(id: e.playerId, name: 'Giocatore', role: PlayerRole.PG, stats: {}));
      return MatchRosterPlayer(
        dbId: dbP.id,
        num: e.customNum ?? '?',
        name: dbP.name,
        role: dbP.role,
        inField: e.isStarter,
      );
    }).toList();
  }
}