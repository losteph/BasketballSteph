// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player_model.dart';
import '../models/match_roster_player.dart';
import '../services/storage_service.dart';

class SquadBuilderScreen extends StatefulWidget {
  final Function(List<MatchRosterPlayer> home, List<MatchRosterPlayer> away)? onSendToScoreboard;

  const SquadBuilderScreen({super.key, this.onSendToScoreboard});

  @override
  State<SquadBuilderScreen> createState() => SquadBuilderScreenState();
}

class SquadBuilderScreenState extends State<SquadBuilderScreen> {
  List<PlayerModel> _allPlayers = [];
  final List<PlayerModel> _team1 = [];
  final List<PlayerModel> _team2 = [];
  int _targetTeam = 1;
  bool _isLoading = true;

  String _searchQuery = '';
  String _roleFilter = 'ALL';
  String _sortBy = 'ovr-desc';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  void reload() {
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final list = await StorageService.loadPlayers();
    setState(() {
      _allPlayers = list;
      _isLoading = false;
    });
  }

  double _calcAvg(List<PlayerModel> team) {
    if (team.isEmpty) return 0.0;
    final total = team.fold<double>(0.0, (acc, p) => acc + p.ovrData.numeric);
    return double.parse((total / team.length).toStringAsFixed(1));
  }

  List<PlayerModel> get _filteredPlayers {
    var result = List<PlayerModel>.from(_allPlayers);

    if (_searchQuery.trim().isNotEmpty) {
      result = result
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_roleFilter != 'ALL') {
      result = result.where((p) => p.role.name == _roleFilter).toList();
    }

    result.sort((a, b) {
      switch (_sortBy) {
        case 'ovr-desc':
          return b.ovrData.numeric.compareTo(a.ovrData.numeric);
        case 'ovr-asc':
          return a.ovrData.numeric.compareTo(b.ovrData.numeric);
        case 'name-asc':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'name-desc':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        default:
          return 0;
      }
    });

    return result;
  }

  void _onPlayerTapped(PlayerModel p) {
    setState(() {
      if (_team1.any((x) => x.id == p.id)) {
        _team1.removeWhere((x) => x.id == p.id);
      } else if (_team2.any((x) => x.id == p.id)) {
        _team2.removeWhere((x) => x.id == p.id);
      } else {
        if (_targetTeam == 1) {
          _team1.add(p);
        } else {
          _team2.add(p);
        }
      }
    });
  }

  void _sendToScoreboard() {
    if (widget.onSendToScoreboard == null) return;
    if (_team1.isEmpty && _team2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno un giocatore per squadra.')),
      );
      return;
    }

    final homeRoster = <MatchRosterPlayer>[];
    for (var i = 0; i < _team1.length; i++) {
      final p = _team1[i];
      homeRoster.add(MatchRosterPlayer(
        dbId: p.id,
        num: '${i + 1}',
        name: p.name,
        role: p.role,
        inField: i < 5,
      ));
    }

    final awayRoster = <MatchRosterPlayer>[];
    for (var i = 0; i < _team2.length; i++) {
      final p = _team2[i];
      awayRoster.add(MatchRosterPlayer(
        dbId: p.id,
        num: '${i + 1}',
        name: p.name,
        role: p.role,
        inField: i < 5,
      ));
    }

    widget.onSendToScoreboard!(homeRoster, awayRoster);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Squadre caricate nello Scoreboard Live!'), backgroundColor: Color(0xFFF97316)),
    );
  }

  Future<void> _copyLineupsToClipboard() async {
    if (_team1.isEmpty && _team2.isEmpty) return;
    final avg1 = _calcAvg(_team1).toStringAsFixed(1);
    final avg2 = _calcAvg(_team2).toStringAsFixed(1);

    var buffer = StringBuffer();
    buffer.writeln('🏀 *FORMAZIONI BASKET*\n');
    buffer.writeln('🔵 *SQUADRA 1* (OVR Medio: $avg1)');
    for (var p in _team1) {
      buffer.writeln('• [${p.role.name}] ${p.name}');
    }
    buffer.writeln('\n🔴 *SQUADRA 2* (OVR Medio: $avg2)');
    for (var p in _team2) {
      buffer.writeln('• [${p.role.name}] ${p.name}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formazioni copiate negli appunti!'), backgroundColor: Color(0xFFF97316)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
    }

    final displayList = _filteredPlayers;
    final totalSelected = _team1.length + _team2.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Box con altezza fissa ed Opacity per evitare il microscatto
          SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Convocati totali: $totalSelected',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
                Opacity(
                  opacity: totalSelected > 0 ? 1.0 : 0.0,
                  child: TextButton(
                    onPressed: totalSelected > 0
                        ? () => setState(() {
                              _team1.clear();
                              _team2.clear();
                            })
                        : null,
                    child: const Text('Svuota', style: TextStyle(color: Color(0xFFEF4444))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FORMAZIONI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: totalSelected > 0 ? _copyLineupsToClipboard : null,
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copia'),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: totalSelected > 0 ? _sendToScoreboard : null,
                    icon: const Icon(Icons.sports_basketball, size: 15),
                    label: const Text('Carica su Match'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _targetTeam = 1),
                  child: _buildTeamCard('Squadra 1', _team1, const Color(0xFF3B82F6), 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _targetTeam = 2),
                  child: _buildTeamCard('Squadra 2', _team2, const Color(0xFFEF4444), 2),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cerca per nome...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Color(0xFF94A3B8)),
                color: const Color(0xFF1E293B),
                onSelected: (val) => setState(() => _sortBy = val),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'ovr-desc', child: Text('OVR Decrescente', style: TextStyle(color: Colors.white, fontSize: 13))),
                  PopupMenuItem(value: 'ovr-asc', child: Text('OVR Crescente', style: TextStyle(color: Colors.white, fontSize: 13))),
                  PopupMenuItem(value: 'name-asc', child: Text('Nome (A-Z)', style: TextStyle(color: Colors.white, fontSize: 13))),
                  PopupMenuItem(value: 'name-desc', child: Text('Nome (Z-A)', style: TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', ...PlayerRole.values.map((r) => r.name)].map((role) {
                final active = _roleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: InkWell(
                    onTap: () => setState(() => _roleFilter = role),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFF97316) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(color: active ? Colors.white : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            itemBuilder: (ctx, i) {
              final p = displayList[i];
              final inT1 = _team1.any((x) => x.id == p.id);
              final inT2 = _team2.any((x) => x.id == p.id);
              final isSel = inT1 || inT2;

              return InkWell(
                onTap: () => _onPlayerTapped(p),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF1E293B) : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSel ? const Color(0xFFF97316) : const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Icon(isSel ? Icons.check_box : Icons.check_box_outline_blank, color: isSel ? const Color(0xFFF97316) : const Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: p.roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(p.role.name, style: TextStyle(color: p.roleColor, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Text('OVR ${p.ovrData.numeric}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String title, List<PlayerModel> team, Color color, int teamIdx) {
    final avg = _calcAvg(team);
    final isSelected = _targetTeam == teamIdx;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFFF97316) : color, width: isSelected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
              if (isSelected) const Text('🎯 ATTIVA', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 9)),
            ],
          ),
          Text('OVR Medio: ${avg == 0 ? "--.-" : avg} (${team.length})', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          const Divider(color: Color(0xFF1E293B)),
          Expanded(
            child: team.isEmpty
                ? const Center(child: Text('Tocca per inserire qui i giocatori', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 10)))
                : ListView.builder(
                    itemCount: team.length,
                    itemBuilder: (ctx, i) {
                      final p = team[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${p.role.name} - ${p.name}', style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (teamIdx == 1) {
                                    _team1.remove(p);
                                    _team2.add(p);
                                  } else {
                                    _team2.remove(p);
                                    _team1.add(p);
                                  }
                                });
                              },
                              child: const Icon(Icons.swap_horiz, size: 14, color: Color(0xFFF97316)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
