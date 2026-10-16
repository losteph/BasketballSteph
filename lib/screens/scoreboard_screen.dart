// ignore_for_file: unused_field, constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/match_roster_player.dart';
import '../models/match_history_model.dart';
import '../models/player_model.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';

class ScoreboardScreen extends StatefulWidget {
  final List<MatchRosterPlayer> initialHomePlayers;
  final List<MatchRosterPlayer> initialAwayPlayers;
  final String? initialHomeName;
  final String? initialAwayName;
  final Color? initialHomeColor;
  final Color? initialAwayColor;
  final VoidCallback? onMatchFinished;
  final String? initialTournamentId;

  const ScoreboardScreen({
    super.key,
    required this.initialHomePlayers,
    required this.initialAwayPlayers,
    this.initialHomeName,
    this.initialAwayName,
    this.initialHomeColor,
    this.initialAwayColor,
    this.onMatchFinished,
    this.initialTournamentId,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  Timer? _matchTimer;
  int _durationSeconds = 10 * 60;
  int _currentSeconds = 10 * 60;
  String _timerMode = 'countdown';
  bool _isMatchRunning = false;
  int _currentPeriod = 1;
  String _periodLabel = '1°Q';

  // Shot Clock (24s / 14s)
  Timer? _shotClockTimer;
  int _shotClockSeconds = 24;
  bool _isShotClockRunning = false;

  final TextEditingController _homeNameCtrl = TextEditingController(text: 'CASA');
  final TextEditingController _awayNameCtrl = TextEditingController(text: 'OSPITI');
  
  final TextEditingController _matchMinCtrl = TextEditingController(text: '10');
  final TextEditingController _matchSecCtrl = TextEditingController(text: '00');

  // Controllers per aggiunta al volo
  final TextEditingController _addNumHomeCtrl = TextEditingController();
  final TextEditingController _addNameHomeCtrl = TextEditingController();
  final TextEditingController _addNumAwayCtrl = TextEditingController();
  final TextEditingController _addNameAwayCtrl = TextEditingController();

  int _homeScore = 0;
  int _awayScore = 0;
  int _homeQuarterFouls = 0;
  int _awayQuarterFouls = 0;

  Color _homeColor = const Color(0xFF3B82F6);
  Color _awayColor = const Color(0xFFEF4444);

  String? _activeTournamentId;

  late List<MatchRosterPlayer> _homePlayers;
  late List<MatchRosterPlayer> _awayPlayers;
  List<MatchRosterPlayer>? _initialLineupHome;
  List<MatchRosterPlayer>? _initialLineupAway;

  final List<MatchEvent> _events = [];

  final Map<String, Color> _colorOptions = const {
    '🔵 Blu': Color(0xFF3B82F6),
    '🔴 Rosso': Color(0xFFEF4444),
    '🟢 Verde': Color(0xFF10B981),
    '🟡 Giallo': Color(0xFFEAB308),
    '🟠 Arancio': Color(0xFFF97316),
    '🟣 Viola': Color(0xFF8B5CF6),
    '⚫ Nero': Color(0xFF1E293B),
    '⚪ Bianco': Color(0xFFF8FAFC),
  };

  String _getTeamEmoji(Color color) {
    if (color == const Color(0xFF3B82F6)) return '🔵';
    if (color == const Color(0xFFEF4444)) return '🔴';
    if (color == const Color(0xFF10B981)) return '🟢';
    if (color == const Color(0xFFEAB308)) return '🟡';
    if (color == const Color(0xFFF97316)) return '🟠';
    if (color == const Color(0xFF8B5CF6)) return '🟣';
    if (color == const Color(0xFF1E293B)) return '⚫';
    if (color == const Color(0xFFF8FAFC)) return '⚪';
    return '🏀';
  }

  @override
  void initState() {
    super.initState();
    _activeTournamentId = widget.initialTournamentId;
    _setupInitialRosters();
  }

  @override
  void didUpdateWidget(covariant ScoreboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activeTournamentId = widget.initialTournamentId;
    if (widget.initialHomePlayers.isNotEmpty &&
        widget.initialHomePlayers != oldWidget.initialHomePlayers) {
      _setupInitialRosters();
      if (widget.initialHomeName != null) {
        _homeNameCtrl.text = widget.initialHomeName!;
      }
      if (widget.initialAwayName != null) {
        _awayNameCtrl.text = widget.initialAwayName!;
      }
      if (widget.initialHomeColor != null) {
        _homeColor = widget.initialHomeColor!;
      }
      if (widget.initialAwayColor != null) {
        _awayColor = widget.initialAwayColor!;
      }
    }
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    _shotClockTimer?.cancel();
    _homeNameCtrl.dispose();
    _awayNameCtrl.dispose();
    _matchMinCtrl.dispose();
    _matchSecCtrl.dispose();
    _addNumHomeCtrl.dispose();
    _addNameHomeCtrl.dispose();
    _addNumAwayCtrl.dispose();
    _addNameAwayCtrl.dispose();
    super.dispose();
  }

  void _setupInitialRosters() {
    if (widget.initialHomePlayers.isNotEmpty) {
      _homePlayers = List.from(widget.initialHomePlayers.map((e) => MatchRosterPlayer.fromJson(e.toJson())));
    } else {
      final defaultRoles = [PlayerRole.PG, PlayerRole.SG, PlayerRole.SF, PlayerRole.PF, PlayerRole.C, PlayerRole.PG, PlayerRole.SF];
      final defaultNames = ['Playmaker (PG)', 'Guardia (SG)', 'Ala Piccola (SF)', 'Ala Grande (PF)', 'Centro (C)', 'Riserva 1', 'Riserva 2'];
      _homePlayers = List.generate(
        7,
        (i) => MatchRosterPlayer(
          dbId: 'h_$i',
          num: '${i + 1}',
          name: defaultNames[i],
          role: defaultRoles[i],
          inField: i < 5,
        ),
      );
    }

    if (widget.initialAwayPlayers.isNotEmpty) {
      _awayPlayers = List.from(widget.initialAwayPlayers.map((e) => MatchRosterPlayer.fromJson(e.toJson())));
    } else {
      final defaultRoles = [PlayerRole.PG, PlayerRole.SG, PlayerRole.SF, PlayerRole.PF, PlayerRole.C, PlayerRole.PG, PlayerRole.SF];
      final defaultNames = ['Playmaker (PG)', 'Guardia (SG)', 'Ala Piccola (SF)', 'Ala Grande (PF)', 'Centro (C)', 'Riserva 1', 'Riserva 2'];
      _awayPlayers = List.generate(
        7,
        (i) => MatchRosterPlayer(
          dbId: 'a_$i',
          num: '${i + 1}',
          name: defaultNames[i],
          role: defaultRoles[i],
          inField: i < 5,
        ),
      );
    }
  }

  void _removePlayerFromRoster(String team, int idx) {
    setState(() {
      if (team == 'home') {
        _homePlayers.removeAt(idx);
      } else {
        _awayPlayers.removeAt(idx);
      }
    });
  }

  void _addPlayerToRoster(String team) {
    final isHome = team == 'home';
    final numCtrl = isHome ? _addNumHomeCtrl : _addNumAwayCtrl;
    final nameCtrl = isHome ? _addNameHomeCtrl : _addNameAwayCtrl;

    final name = nameCtrl.text.trim();
    final num = numCtrl.text.trim();

    if (name.isEmpty) return;

    setState(() {
      final newPlayer = MatchRosterPlayer(
        dbId: '${team}_new_${DateTime.now().millisecondsSinceEpoch}',
        num: num.isEmpty ? '?' : num,
        name: name,
        role: PlayerRole.PG,
        inField: true,
      );

      if (isHome) {
        _homePlayers.add(newPlayer);
      } else {
        _awayPlayers.add(newPlayer);
      }
      
      numCtrl.clear();
      nameCtrl.clear();
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _getElapsedFormatted() {
    if (_timerMode == 'countdown') {
      final elapsed = _durationSeconds - _currentSeconds;
      return '$_periodLabel ${_formatTime(elapsed < 0 ? 0 : elapsed)}';
    } else {
      return '$_periodLabel ${_formatTime(_currentSeconds)}';
    }
  }

  void _setTimerMode(String mode) {
    if (_timerMode == mode) return;
    setState(() {
      _timerMode = mode;
      _currentSeconds = (_durationSeconds - _currentSeconds).clamp(0, _durationSeconds);
    });
  }

  void _applyDurationSettings() {
    int m = int.tryParse(_matchMinCtrl.text) ?? 10;
    int s = int.tryParse(_matchSecCtrl.text) ?? 0;
    setState(() {
      _durationSeconds = (m * 60) + s;
      _currentSeconds = _timerMode == 'countdown' ? _durationSeconds : 0;
    });
  }

  void _toggleMatchTimer() {
    if (_isMatchRunning) {
      _matchTimer?.cancel();
      setState(() => _isMatchRunning = false);
      if (_isShotClockRunning) _toggleShotClock();
    } else {
      if (_currentPeriod == 1 && _initialLineupHome == null) {
        setState(() {
          _initialLineupHome = _homePlayers.map((p) => MatchRosterPlayer.fromJson(p.toJson())).toList();
          _initialLineupAway = _awayPlayers.map((p) => MatchRosterPlayer.fromJson(p.toJson())).toList();
        });
      }
      _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          for (final p in _homePlayers) {
            if (p.inField) p.playedSeconds++;
          }
          for (final p in _awayPlayers) {
            if (p.inField) p.playedSeconds++;
          }

          if (_timerMode == 'countdown') {
            if (_currentSeconds > 0) {
              _currentSeconds--;
            } else {
              _finishTimer();
            }
          } else {
            if (_currentSeconds < _durationSeconds) {
              _currentSeconds++;
            } else {
              _finishTimer();
            }
          }
        });
      });
      setState(() => _isMatchRunning = true);
    }
  }

  void _finishTimer() {
    _matchTimer?.cancel();
    setState(() => _isMatchRunning = false);
    if (_isShotClockRunning) _toggleShotClock();
    SoundService.playWhistle();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚨 SIRENA FINE $_periodLabel!'), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  void _toggleShotClock() {
    if (_isShotClockRunning) {
      _shotClockTimer?.cancel();
      setState(() => _isShotClockRunning = false);
    } else {
      _shotClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_shotClockSeconds > 0) {
            _shotClockSeconds--;
          } else {
            _shotClockTimer?.cancel();
            _isShotClockRunning = false;
            SoundService.playBell();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏰ INFRAZIONE 24 SECONDI!'),
                backgroundColor: Color(0xFFEF4444),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      });
      setState(() => _isShotClockRunning = true);
    }
  }

  void _resetShotClock(int val) {
    setState(() => _shotClockSeconds = val);
  }

  void _selectPeriod(int num, String shortLabel, String fullLabel) {
    setState(() {
      _currentPeriod = num;
      _periodLabel = shortLabel;
      _homeQuarterFouls = 0;
      _awayQuarterFouls = 0;
      if (shortLabel.contains('OT')) {
        _durationSeconds = 5 * 60;
        _matchMinCtrl.text = '5';
      } else {
        _durationSeconds = 10 * 60;
        _matchMinCtrl.text = '10';
      }
      _currentSeconds = _timerMode == 'countdown' ? _durationSeconds : 0;
      _shotClockSeconds = 24;
    });
    _logEvent('⏱️ Inizio $fullLabel', 'Falli squadra azzerati', _getElapsedFormatted());
  }

  void _quickScore(String team, int pts) {
    final isHome = team == 'home';
    final teamName = isHome ? _homeNameCtrl.text : _awayNameCtrl.text;
    setState(() {
      if (isHome) {
        _homeScore += pts;
      } else {
        _awayScore += pts;
      }
      _resetShotClock(24);
    });

    final label = pts == 3 ? '🎯 TRIPLA (+3)' : (pts == 2 ? '🏀 CANESTRO (+2)' : '☄️ LIBERO (+1)');
    final evType = pts == 3 ? 'SCORE_3PT' : (pts == 2 ? 'SCORE_2PT' : 'SCORE_1PT');
    _logEvent(label, 'Squadra: $teamName', _getElapsedFormatted(), team: team, pts: pts, type: evType);
  }

  void _promptMinusScore(String team) {
    final targetList = _events.where((e) => e.team == team && e.pts > 0).toList();

    if (targetList.isEmpty) {
      setState(() {
        if (team == 'home') {
          _homeScore = (_homeScore - 1).clamp(0, 999);
        } else {
          _awayScore = (_awayScore - 1).clamp(0, 999);
        }
      });
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Quale canestro vuoi annullare?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targetList.length,
            itemBuilder: (c, i) {
              final ev = targetList[i];
              return ListTile(
                title: Text('${ev.minute} - ${ev.title}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  _deleteEvent(ev);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  void _logEvent(String title, String sub, String minute, {String? team, int pts = 0, String type = 'OTHER', String? playerId}) {
    setState(() {
      _events.insert(0, MatchEvent(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        sub: sub,
        minute: minute,
        team: team,
        pts: pts,
        type: type,
        playerId: playerId,
      ));
    });
  }

  void _deleteEvent(MatchEvent ev) {
    setState(() {
      if (ev.pts > 0) {
        if (ev.team == 'home') _homeScore = (_homeScore - ev.pts).clamp(0, 999);
        if (ev.team == 'away') _awayScore = (_awayScore - ev.pts).clamp(0, 999);
      }
      if (ev.type == 'FOUL') {
        if (ev.team == 'home') _homeQuarterFouls = (_homeQuarterFouls - 1).clamp(0, 99);
        if (ev.team == 'away') _awayQuarterFouls = (_awayQuarterFouls - 1).clamp(0, 99);
        if (ev.playerId != null) {
          final p = [..._homePlayers, ..._awayPlayers].firstWhere(
            (x) => x.dbId == ev.playerId,
            orElse: () => MatchRosterPlayer(dbId: '', num: '', name: ''),
          );
          if (p.fouls > 0) p.fouls--;
        }
      }
      _events.removeWhere((e) => e.id == ev.id);
    });
  }

  void _confirmEndMatch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Conferma Fine Partita', style: TextStyle(color: Colors.white)),
        content: const Text('Terminare la gara e salvare i dati nello storico?', style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Annulla', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              
              if (_isMatchRunning) _toggleMatchTimer();
              if (_isShotClockRunning) _toggleShotClock();

              final finalHomeRoster = (_initialLineupHome ?? _homePlayers).map((initP) {
                final updatedP = _homePlayers.firstWhere((p) => p.dbId == initP.dbId, orElse: () => initP);
                final copy = MatchRosterPlayer.fromJson(initP.toJson());
                copy.playedSeconds = updatedP.playedSeconds;
                copy.fouls = updatedP.fouls;
                return copy;
              }).toList();

              final finalAwayRoster = (_initialLineupAway ?? _awayPlayers).map((initP) {
                final updatedP = _awayPlayers.firstWhere((p) => p.dbId == initP.dbId, orElse: () => initP);
                final copy = MatchRosterPlayer.fromJson(initP.toJson());
                copy.playedSeconds = updatedP.playedSeconds;
                copy.fouls = updatedP.fouls;
                return copy;
              }).toList();

              final now = DateTime.now();
              final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

              final newMatch = MatchHistoryModel(
                id: 'match_${now.millisecondsSinceEpoch}',
                title: '${_homeNameCtrl.text} vs ${_awayNameCtrl.text}',
                date: dateStr,
                tournamentId: widget.initialTournamentId,
                homeName: _homeNameCtrl.text,
                awayName: _awayNameCtrl.text,
                homeColorValue: _homeColor.toARGB32(),
                awayColorValue: _awayColor.toARGB32(),
                homeScore: _homeScore,
                awayScore: _awayScore,
                homeRoster: finalHomeRoster,
                awayRoster: finalAwayRoster,
                events: _events,
              );

              final currentMatches = await StorageService.loadMatches();
              currentMatches.insert(0, newMatch);
              await StorageService.saveMatches(currentMatches);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partita archiviata con successo!'), backgroundColor: Color(0xFF10B981)),
                );
                widget.onMatchFinished?.call();
              }
            },
            child: const Text('Fine Partita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- CALCOLO PAGELLINI BASKET ---
  Map<String, dynamic> _calculateRatings() {
    final Map<String, List<Map<String, dynamic>>> res = {'home': [], 'away': []};
    final hWon = _homeScore > _awayScore;
    final aWon = _awayScore > _homeScore;


    for (final team in ['home', 'away']) {
      final isHome = team == 'home';
      final won = isHome ? hWon : aWon;
      final lost = isHome ? aWon : hWon;
      final list = isHome ? _homePlayers : _awayPlayers;

      for (final p in list) {
        int pts1 = 0, pts2 = 0, pts3 = 0, assists = 0, rebounds = 0, fouls = 0, goodPlays = 0, turnovers = 0;

        for (final e in _events) {
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
        final bool playedEnough = p.playedSeconds >= 180; // 3 minuti

        if (!hasAction && !playedEnough) {
          res[team]!.add({
            'id': p.dbId,
            'num': p.num,
            'name': p.name,
            'role': p.role.name,
            'score': 'SV',
            'details': 'Meno di 3m e 0 pt/assist',
          });
          continue;
        }

        double score = 6.0;
        final details = <String>[];

        if (won) { score += 0.2; details.add('+0.2 vittoria'); }
        else if (lost) { score -= 0.1; details.add('-0.1 sconfitta'); }

        if (pts3 > 0) { score += (pts3 * 0.5); details.add('+${(pts3 * 0.5).toStringAsFixed(1)} 3PT'); }
        if (pts2 > 0) { score += (pts2 * 0.3); details.add('+${(pts2 * 0.3).toStringAsFixed(1)} 2PT'); }
        if (pts1 > 0) { score += (pts1 * 0.1); details.add('+${(pts1 * 0.1).toStringAsFixed(1)} 1PT'); }
        if (assists > 0) { score += (assists * 0.2); details.add('+${(assists * 0.2).toStringAsFixed(1)} assist'); }
        if (goodPlays > 0) { score += (goodPlays * 0.1); details.add('+${(goodPlays * 0.3).toStringAsFixed(1)} buone'); }
        if (rebounds > 0) { score += (rebounds * 0.2); details.add('+${(rebounds * 0.1).toStringAsFixed(1)} rimb'); }
        if (turnovers > 0) { score -= (turnovers * 0.2); details.add('-${(turnovers * 0.2).toStringAsFixed(1)} palle perse'); }
        if (fouls > 0) { score -= (fouls * 0.4); details.add('-${(fouls * 0.4).toStringAsFixed(1)} falli'); }

        final rounded = double.parse(score.clamp(1.0, 9.9).toStringAsFixed(1));


        res[team]!.add({
          'id': p.dbId,
          'num': p.num,
          'name': p.name,
          'role': p.role.name,
          'score': rounded.toStringAsFixed(1),
          'details': details.isNotEmpty ? details.join(', ') : 'Base 6.0',
        });
      }
    }

    return {
      'ratings': res,
    };
  }

  void _openPlayerActionModal(String team, int idx) {
    final list = team == 'home' ? _homePlayers : _awayPlayers;
    final p = list[idx];
    final teamName = team == 'home' ? _homeNameCtrl.text : _awayNameCtrl.text;

    final nameController = TextEditingController(text: p.name);
    final numController = TextEditingController(text: p.num);
    String? selectedAssist;

    final potentialAssists = list.where((x) => x.dbId != p.dbId).toList();
    final benchTargets = list.where((x) => x.inField != p.inField).toList();
    MatchRosterPlayer? selectedSubTarget = benchTargets.isNotEmpty ? benchTargets.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🏀 #${p.num} ${p.name} ($teamName)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: p.fouls >= 5 ? const Color(0xFFEF4444) : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
                      child: Text('Falli: ${p.fouls}/5', style: TextStyle(color: p.fouls >= 5 ? Colors.white : const Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: numController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(labelText: 'N°', filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: 'Nome Giocatore', filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedAssist,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(labelText: 'Assistito da (Opzionale)', filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Nessun Assist')),
                    ...potentialAssists.map((m) => DropdownMenuItem(value: '#${m.num} ${m.name}', child: Text('#${m.num} ${m.name}'))),
                  ],
                  onChanged: (val) => setMState(() => selectedAssist = val),
                ),
                const SizedBox(height: 14),

                // Griglia Azioni Basket
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3.5,
                  children: [
                    _actionBtn('🎯 Tripla (+3)', () { _triggerAction(team, p, 'SCORE_3PT', pts: 3, assist: selectedAssist); Navigator.pop(ctx); }, textColor: const Color(0xFF93C5FD)),
                    _actionBtn('🏀 Canestro (+2)', () { _triggerAction(team, p, 'SCORE_2PT', pts: 2, assist: selectedAssist); Navigator.pop(ctx); }, textColor: const Color(0xFFFF9D5C)),
                    _actionBtn('☄️ Libero (+1)', () { _triggerAction(team, p, 'SCORE_1PT', pts: 1, assist: selectedAssist); Navigator.pop(ctx); }, textColor: const Color.fromARGB(255, 224, 224, 98)),
                    _actionBtn('🖐️ Rimbalzo', () { _triggerAction(team, p, 'REBOUND'); Navigator.pop(ctx); }, textColor: const Color(0xFFC4B5FD)),
                    _actionBtn('⭐ Buona Azione / Stoppata', () { _triggerAction(team, p, 'GOOD_PLAY'); Navigator.pop(ctx); }, textColor: const Color(0xFF10B981)),
                    _actionBtn('❌ Palla Persa / Errore', () { _triggerAction(team, p, 'TURNOVER'); Navigator.pop(ctx); }, textColor: const Color(0xFFEAB308)),
                  ],
                ),

                const SizedBox(height: 8),

                // Tasto Fallo a tutta larghezza (copre entrambi i blocchi)
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: _actionBtn(
                    '⚠️ Fallo Personale',
                    () { _triggerAction(team, p, 'FOUL'); Navigator.pop(ctx); },
                    textColor: const Color(0xFFEF4444),
                  ),
                ),

                const SizedBox(height: 14),

                if (benchTargets.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF334155))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.inField ? 'SOSTITUISCI CON PANCHINARO:' : 'SCHIERA IN CAMPO AL POSTO DI:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<MatchRosterPlayer>(
                                initialValue: selectedSubTarget,
                                dropdownColor: const Color(0xFF111827),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: benchTargets.map((t) => DropdownMenuItem(value: t, child: Text('#${t.num} ${t.name}'))).toList(),
                                onChanged: (v) => setMState(() => selectedSubTarget = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
                              onPressed: () {
                                if (selectedSubTarget != null) { _executeSubstitution(team, p, selectedSubTarget!); Navigator.pop(ctx); }
                              },
                              child: const Text('🔄 Cambia'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155))), child: const Text('Chiudi', style: TextStyle(color: Color(0xFF94A3B8))))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF042F22)),
                        onPressed: () {
                          setState(() { p.name = nameController.text.trim(); p.num = numController.text.trim(); });
                          Navigator.pop(ctx);
                        },
                        child: const Text('💾 Salva Info', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _actionBtn(String label, VoidCallback onTap, {Color textColor = Colors.white}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF334155))),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  void _triggerAction(String team, MatchRosterPlayer p, String type, {int pts = 0, String? assist}) {
    final teamName = team == 'home' ? _homeNameCtrl.text : _awayNameCtrl.text;
    final min = _getElapsedFormatted();

    setState(() {
      if (pts > 0) {
        if (team == 'home') {
          _homeScore += pts;
        } else {
          _awayScore += pts;
        }
        _resetShotClock(24);

        String title = pts == 3 ? '🎯 TRIPLA (+3) #${p.num} ${p.name}' : (pts == 2 ? '🏀 CANESTRO (+2) #${p.num} ${p.name}' : '☄️ LIBERO (+1) #${p.num} ${p.name}');
        String sub = 'Squadra: $teamName';
        if (assist != null) sub += ' • 🅰 Assist: $assist';
        _logEvent(title, sub, min, team: team, pts: pts, type: type, playerId: p.dbId);
      } else if (type == 'FOUL') {
        p.fouls++;
        if (team == 'home') {
          _homeQuarterFouls++;
        } else {
          _awayQuarterFouls++;
        }
        _logEvent('⚠️ Fallo #${p.num} ${p.name} (${p.fouls}/5)', 'Squadra: $teamName', min, team: team, type: 'FOUL', playerId: p.dbId);
        if (p.fouls >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ #${p.num} ${p.name} ha commesso 5 falli!'), backgroundColor: const Color(0xFFEF4444)));
        }
      } else if (type == 'REBOUND') {
        _resetShotClock(14);
        _logEvent('🖐️ Rimbalzo: #${p.num} ${p.name}', 'Squadra: $teamName', min, team: team, type: 'REBOUND', playerId: p.dbId);
      } else if (type == 'TURNOVER') {
        _logEvent('❌ Errore: #${p.num} ${p.name}', 'Squadra: $teamName', min, team: team, type: 'TURNOVER', playerId: p.dbId);
      } else if (type == 'GOOD_PLAY') {
        _logEvent('⭐ Buona Azione: #${p.num} ${p.name}', 'Squadra: $teamName', min, team: team, type: 'GOOD_PLAY', playerId: p.dbId);
      }
    });
  }

  void _executeSubstitution(String team, MatchRosterPlayer current, MatchRosterPlayer target) {
    setState(() {
      current.inField = !current.inField;
      target.inField = !target.inField;
    });
    final inP = current.inField ? current : target;
    final outP = current.inField ? target : current;
    final name = team == 'home' ? _homeNameCtrl.text : _awayNameCtrl.text;
    _logEvent('🔄 Sostituzione', 'Entra #${inP.num} ${inP.name}, Esce #${outP.num} ${outP.name} ($name)', _getElapsedFormatted(), team: team, type: 'SUB');
  }

  void _openPagelleModal() {
    final eval = _calculateRatings();
    final Map<String, List<Map<String, dynamic>>> ratings = eval['ratings'];
    final String? mvpId = eval['mvpId'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('⭐ Pagelle della Partita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_homeNameCtrl.text.toUpperCase(), style: TextStyle(color: _homeColor, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                ...ratings['home']!.map((r) => _pagellaTile(r, mvpId)),
                const Divider(color: Color(0xFF334155), height: 20),
                Text(_awayNameCtrl.text.toUpperCase(), style: TextStyle(color: _awayColor, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                ...ratings['away']!.map((r) => _pagellaTile(r, mvpId)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final hEmoji = _getTeamEmoji(_homeColor);
              final aEmoji = _getTeamEmoji(_awayColor);
              var text = '🏀 *PAGELLINE BASKET*\n🏆 ${_homeNameCtrl.text} $_homeScore - $_awayScore ${_awayNameCtrl.text}\n\n';
              
              text += '$hEmoji *${_homeNameCtrl.text}*\n';
              for (final r in ratings['home']!) {
                final isMvp = r['id'] == mvpId && r['score'] != 'SV';
                text += '• _#${r['num']} ${r['name']}:_ *${r['score']}* ${isMvp ? "⭐ MVP" : ""}\n';
              }
              
              text += '\n$aEmoji *${_awayNameCtrl.text}*\n';
              for (final r in ratings['away']!) {
                final isMvp = r['id'] == mvpId && r['score'] != 'SV';
                text += '• _#${r['num']} ${r['name']}:_ *${r['score']}* ${isMvp ? "⭐ MVP" : ""}\n';
              }
              
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pagelle copiate negli appunti!')));
              }
            },
            child: const Text('📋 Copia', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Chiudi', style: TextStyle(color: Color(0xFF94A3B8)))),
        ],
      ),
    );
  }

  Widget _pagellaTile(Map<String, dynamic> r, String? mvpId) {
    final isMvp = r['id'] == mvpId && r['score'] != 'SV';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
                  child: Text(r['role'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('#${r['num']} ${r['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              r['score'],
              style: TextStyle(
                color: isMvp ? Colors.white : (r['score'] == 'SV' ? const Color(0xFF94A3B8) : const Color(0xFF10B981)),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareCurrentMatch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('📲 Condividi Tabellino', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scegli quale formato di cronaca esportare:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF042F22), minimumSize: const Size.fromHeight(44)),
              onPressed: () { Navigator.pop(ctx); _processShare(true); },
              child: const Text('🌟 Solo Azioni Salienti\n(Canestri, Tiri Liberi, Falli)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
              onPressed: () { Navigator.pop(ctx); _processShare(false); },
              child: const Text('📜 Cronaca Completa\n(Include anche rimbalzi e palle perse)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processShare(bool onlyHighlights) async {
    final hName = _homeNameCtrl.text;
    final aName = _awayNameCtrl.text;
    final hEmoji = _getTeamEmoji(_homeColor);
    final aEmoji = _getTeamEmoji(_awayColor);
    
    String text = '🏆 *TABELLINO BASKET: $hName vs $aName*\n';
    text += '🏀 $hEmoji $hName $_homeScore - $_awayScore $aName $aEmoji\n';
    
    text += '\n👥 *ROSTER:*\n';
    
    String formatLineup(String name, List<MatchRosterPlayer> roster, String emoji) {
      String block = '• $emoji *$name*\n  - In campo:\n';
      final inField = roster.where((p) => p.inField).toList();
      final bench = roster.where((p) => !p.inField).toList();
      if (inField.isEmpty) block += '    • Nessuno\n';
      for (var p in inField) {
        block += '    • #${p.num} ${p.name} (${p.role.name})\n';
      }
      block += '  - Panchina:\n';
      if (bench.isEmpty) block += '    • Nessuno\n';
      for (var p in bench) {
        block += '    • #${p.num} ${p.name} (${p.role.name})\n';
      }
      return block;
    }
    
    text += formatLineup(hName, _initialLineupHome ?? _homePlayers, hEmoji);
    text += formatLineup(aName, _initialLineupAway ?? _awayPlayers, aEmoji);
    
    text += onlyHighlights ? '\n📜 *AZIONI SALIENTI:*\n' : '\n📜 *CRONACA COMPLETA:*\n';
    
    final filteredEvents = onlyHighlights
        ? _events.where((e) => e.type.startsWith('SCORE') || e.type == 'FOUL').toList()
        : _events.toList();
    
    if (filteredEvents.isEmpty) {
      text += '- Nessun evento registrato.\n';
    } else {
      for (var e in filteredEvents.reversed) {
        text += '• [${e.minute}] ${e.title} (${e.sub})\n';
      }
    }
    
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(onlyHighlights ? 'Tabellino (Azioni Salienti) copiato!' : 'Tabellino Completo copiato!')));
    }
  }

  Widget _numInput(TextEditingController ctrl, String suffix) {
    return Row(
      children: [
        SizedBox(
          width: 35, height: 26,
          child: TextField(
            controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: Color(0xFF1E293B), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4)))),
          ),
        ),
        const SizedBox(width: 2),
        Text(suffix, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeInField = _homePlayers.where((p) => p.inField).length;
    final awayInField = _awayPlayers.where((p) => p.inField).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header Timer Partita + Shot Clock 24s
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF334155))),
                          child: Text(_periodLabel.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF8B5CF6))),
                          child: Text('$homeInField vs $awayInField', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_timerMode == 'countdown' ? 'Conto alla Rovescia' : 'In Avanti', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _formatTime(_currentSeconds),
                      style: TextStyle(fontFamily: 'Courier', fontSize: 28, fontWeight: FontWeight.w900, color: (_timerMode == 'countdown' && _currentSeconds <= 10 && _currentSeconds > 0) ? const Color(0xFFEF4444) : const Color(0xFFF97316)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEF4444))),
                      child: Column(
                        children: [
                          const Text('SHOT ⏰', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                          Text('$_shotClockSeconds', style: const TextStyle(fontFamily: 'Courier', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Configurazione Manuale Tempi & Shot Clock
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Modalità Timer:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ChoiceChip(label: const Text('Rovescia ⏳', style: TextStyle(fontSize: 10)), selected: _timerMode == 'countdown', onSelected: (_) => _setTimerMode('countdown'), selectedColor: const Color(0xFFF97316)),
                        const SizedBox(width: 6),
                        ChoiceChip(label: const Text('Avanti ⏱️', style: TextStyle(fontSize: 10)), selected: _timerMode == 'countup', onSelected: (_) => _setTimerMode('countup'), selectedColor: const Color(0xFFF97316)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Durata Quarto:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _numInput(_matchMinCtrl, 'm'), const SizedBox(width: 6), _numInput(_matchSecCtrl, 's'), const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), minimumSize: const Size(0, 26)),
                          onPressed: _applyDurationSettings, child: const Text('Set', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Possesso (24s / 14s):', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _isShotClockRunning ? const Color(0xFFF59E0B) : const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), minimumSize: const Size(0, 26)),
                          onPressed: _toggleShotClock, child: Text(_isShotClockRunning ? 'Pausa' : '▶ Start', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), minimumSize: const Size(0, 26)),
                          onPressed: () => _resetShotClock(24), child: const Text('24s', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), minimumSize: const Size(0, 26)),
                          onPressed: () => _resetShotClock(14), child: const Text('14s', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tabellone Punteggio Casa vs Ospiti
          Row(
            children: [
              Expanded(
                child: _teamScoreCard(
                  nameCtrl: _homeNameCtrl, score: _homeScore, fouls: _homeQuarterFouls, color: _homeColor,
                  onColorChange: (c) => setState(() => _homeColor = c),
                  onScore: (pts) => _quickScore('home', pts),
                  onMinus: () => _promptMinusScore('home'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _teamScoreCard(
                  nameCtrl: _awayNameCtrl, score: _awayScore, fouls: _awayQuarterFouls, color: _awayColor,
                  onColorChange: (c) => setState(() => _awayColor = c),
                  onScore: (pts) => _quickScore('away', pts),
                  onMinus: () => _promptMinusScore('away'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Controlli Principali Timer e Fine
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _isMatchRunning ? const Color(0xFFF59E0B) : const Color(0xFFF97316), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: _toggleMatchTimer, icon: Icon(_isMatchRunning ? Icons.pause : Icons.play_arrow), label: Text(_isMatchRunning ? 'PAUSA' : 'AVVIA TIMER', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)), foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    setState(() {
                      _homeScore = 0; _awayScore = 0; _homeQuarterFouls = 0; _awayQuarterFouls = 0;
                      _events.clear(); _currentSeconds = _durationSeconds; _matchTimer?.cancel(); _isMatchRunning = false;
                      _shotClockTimer?.cancel(); _isShotClockRunning = false; _shotClockSeconds = 24;
                      _initialLineupHome = null; _initialLineupAway = null;
                      _setupInitialRosters();
                    });
                  },
                  child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: _confirmEndMatch, child: const Text('FINE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Selettore Quarti e Overtime
          Row(
            children: [
              _periodBtn(1, '1°Q', '1° Quarto'), _periodBtn(2, '2°Q', '2° Quarto'), _periodBtn(3, '3°Q', '3° Quarto'),
              _periodBtn(4, '4°Q', '4° Quarto'), _periodBtn(5, '1°OT', '1° Overtime'), _periodBtn(6, '2°OT', '2° Overtime'),
            ],
          ),

          const SizedBox(height: 14),

          // Rose Giocatori Basket
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _rosterColumn('home', _homeNameCtrl.text, _homeColor, _homePlayers)),
              const SizedBox(width: 8),
              Expanded(child: _rosterColumn('away', _awayNameCtrl.text, _awayColor, _awayPlayers)),
            ],
          ),

          const SizedBox(height: 14),

          // Feed Cronaca Live
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CRONACA LIVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                    Text('${_events.length} Eventi', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 8),
                if (_events.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Nessun evento registrato.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))))
                else
                  ..._events.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(e.sub, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(e.minute, style: const TextStyle(fontFamily: 'Courier', color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(width: 6),
                                InkWell(onTap: () => _deleteEvent(e), child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444))),
                              ],
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tasto Pagelle & Condivisione
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF042F22), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _openPagelleModal,
                  icon: const Icon(Icons.star),
                  label: const Text('PAGELLE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _shareCurrentMatch,
                  icon: const Icon(Icons.share),
                  label: const Text('CONDIVIDI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamScoreCard({
    required TextEditingController nameCtrl,
    required int score,
    required int fouls,
    required Color color,
    required ValueChanged<Color> onColorChange,
    required ValueChanged<int> onScore,
    required VoidCallback onMinus,
  }) {
    final isBonus = fouls >= 5;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    PopupMenuButton<Color>(
                      icon: const Icon(Icons.circle, size: 18), color: const Color(0xFF1E293B), onSelected: onColorChange,
                      itemBuilder: (ctx) => _colorOptions.entries.map((e) => PopupMenuItem(value: e.value, child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
                    ),
                    Expanded(child: TextField(controller: nameCtrl, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14), decoration: const InputDecoration(border: InputBorder.none, isDense: true))),
                  ],
                ),
                Text('$score', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBonus ? const Color(0x33EF4444) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isBonus ? const Color(0xFFEF4444) : const Color(0xFF334155)),
                  ),
                  child: Text(
                    isBonus ? '🚨 BONUS ($fouls F)' : 'Falli: $fouls/4',
                    style: TextStyle(
                      color: isBonus ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0x33F97316), side: const BorderSide(color: Color(0xFFF97316)), padding: const EdgeInsets.symmetric(vertical: 6)), onPressed: () => onScore(3), child: const Text('+3', style: TextStyle(color: Color(0xFFFF9D5C), fontWeight: FontWeight.bold, fontSize: 11)))),
                    const SizedBox(width: 4),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0x333B82F6), side: const BorderSide(color: Color(0xFF3B82F6)), padding: const EdgeInsets.symmetric(vertical: 6)), onPressed: () => onScore(2), child: const Text('+2', style: TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.bold, fontSize: 11)))),
                    const SizedBox(width: 4),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0x3310B981), side: const BorderSide(color: Color(0xFF10B981)), padding: const EdgeInsets.symmetric(vertical: 6)), onPressed: () => onScore(1), child: const Text('+1', style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 11)))),
                    const SizedBox(width: 4),
                    InkWell(onTap: onMinus, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF334155)), borderRadius: BorderRadius.circular(4)), child: const Text('-', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodBtn(int num, String shortLabel, String fullLabel) {
    final active = _currentPeriod == num;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(backgroundColor: active ? const Color(0xFFF97316) : const Color(0xFF111827), foregroundColor: active ? Colors.white : const Color(0xFF94A3B8), side: BorderSide(color: active ? const Color(0xFFF97316) : const Color(0xFF334155)), padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          onPressed: () => _selectPeriod(num, shortLabel, fullLabel), child: Text(shortLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _rosterColumn(String teamKey, String title, Color borderCol, List<MatchRosterPlayer> roster) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: borderCol,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: TextStyle(color: borderCol, fontWeight: FontWeight.w900, fontSize: 11)),
                const SizedBox(height: 6),
                ...roster.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: p.inField ? const Color(0xFF1E293B) : const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: p.inField ? const Color(0xFF334155) : const Color(0xFF1E293B))),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _openPlayerActionModal(teamKey, idx),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '#${p.num} ${p.name}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: p.inField ? Colors.white : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (p.fouls > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: p.fouls >= 5 ? const Color(0xFFEF4444) : const Color(0x33EF4444), borderRadius: BorderRadius.circular(4)),
                                      child: Text('${p.fouls}F', style: TextStyle(color: p.fouls >= 5 ? Colors.white : const Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => p.inField = !p.inField),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: p.inField ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(4)), child: Text(p.inField ? 'IN' : 'OUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: p.inField ? const Color(0xFF10B981) : const Color(0xFF64748B)))),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removePlayerFromRoster(teamKey, idx),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444))),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 6),
                // Riga Aggiunta Giocatore on the go
                Row(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 28,
                      child: TextField(
                        controller: teamKey == 'home' ? _addNumHomeCtrl : _addNumAwayCtrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: '#', hintStyle: TextStyle(color: Color(0xFF64748B)),
                          contentPadding: EdgeInsets.zero,
                          filled: true, fillColor: Color(0xFF1E293B),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: TextField(
                          controller: teamKey == 'home' ? _addNameHomeCtrl : _addNameAwayCtrl,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'Nome', hintStyle: TextStyle(color: Color(0xFF64748B)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6),
                            filled: true, fillColor: Color(0xFF1E293B),
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _addPlayerToRoster(teamKey),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        child: const Text('+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
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
}