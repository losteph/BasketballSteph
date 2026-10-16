// ignore_for_file: constant_identifier_names

import 'player_model.dart';

class MatchRosterPlayer {
  final String dbId;
  String num;
  String name;
  PlayerRole role;
  bool inField;
  int fouls;
  int playedSeconds;

  MatchRosterPlayer({
    required this.dbId,
    required this.num,
    required this.name,
    this.role = PlayerRole.PG,
    this.inField = true,
    this.fouls = 0,
    this.playedSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
    'dbId': dbId,
    'num': num,
    'name': name,
    'role': role.name,
    'inField': inField,
    'fouls': fouls,
    'playedSeconds': playedSeconds,
  };

  factory MatchRosterPlayer.fromJson(Map<String, dynamic> json) => MatchRosterPlayer(
    dbId: json['dbId'] as String? ?? '',
    num: json['num'] as String? ?? '?',
    name: json['name'] as String? ?? 'Giocatore',
    role: PlayerRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => PlayerRole.PG,
    ),
    inField: json['inField'] as bool? ?? true,
    fouls: json['fouls'] as int? ?? 0,
    playedSeconds: json['playedSeconds'] as int? ?? 0,
  );
}