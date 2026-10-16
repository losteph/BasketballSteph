// ignore_for_file: constant_identifier_names

import 'match_roster_player.dart';

class MatchEvent {
  final int id;
  final String title;
  final String sub;
  final String minute; // Es: "1°Q 08:32" oppure "2°OT"
  final String? team;   // 'home' o 'away'
  final int pts;        // 1, 2 o 3 punti
  final String type;    // 'SCORE_1PT', 'SCORE_2PT', 'SCORE_3PT', 'FOUL', 'REBOUND', 'TURNOVER', 'STEAL', 'SUB', 'OTHER'
  final String? playerId;

  MatchEvent({
    required this.id,
    required this.title,
    required this.sub,
    required this.minute,
    this.team,
    this.pts = 0,
    this.type = 'OTHER',
    this.playerId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sub': sub,
    'minute': minute,
    'team': team,
    'pts': pts,
    'type': type,
    'playerId': playerId,
  };

  factory MatchEvent.fromJson(Map<String, dynamic> json) => MatchEvent(
    id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    title: json['title'] as String? ?? '',
    sub: json['sub'] as String? ?? '',
    minute: json['minute'] as String? ?? '--:--',
    team: json['team'] as String?,
    pts: json['pts'] as int? ?? 0,
    type: json['type'] as String? ?? 'OTHER',
    playerId: json['playerId'] as String?,
  );
}

class MatchHistoryModel {
  final String id;
  String title;
  final String date;
  final String? tournamentId;
  final String homeName;
  final String awayName;
  final int homeColorValue;
  final int awayColorValue;
  final int homeScore;
  final int awayScore;
  final List<MatchRosterPlayer> homeRoster;
  final List<MatchRosterPlayer> awayRoster;
  final List<MatchEvent> events;

  MatchHistoryModel({
    required this.id,
    required this.title,
    required this.date,
    this.tournamentId,
    required this.homeName,
    required this.awayName,
    required this.homeColorValue,
    required this.awayColorValue,
    required this.homeScore,
    required this.awayScore,
    required this.homeRoster,
    required this.awayRoster,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'tournamentId': tournamentId,
    'homeName': homeName,
    'awayName': awayName,
    'homeColorValue': homeColorValue,
    'awayColorValue': awayColorValue,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'homeRoster': homeRoster.map((p) => p.toJson()).toList(),
    'awayRoster': awayRoster.map((p) => p.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
  };

  factory MatchHistoryModel.fromJson(Map<String, dynamic> json) => MatchHistoryModel(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? 'Partita Basket',
    date: json['date'] as String? ?? '',
    tournamentId: json['tournamentId'] as String?,
    homeName: json['homeName'] as String? ?? 'CASA',
    awayName: json['awayName'] as String? ?? 'OSPITI',
    homeColorValue: json['homeColorValue'] as int? ?? 0xFF3B82F6,
    awayColorValue: json['awayColorValue'] as int? ?? 0xFFEF4444,
    homeScore: json['homeScore'] as int? ?? 0,
    awayScore: json['awayScore'] as int? ?? 0,
    homeRoster: (json['homeRoster'] as List? ?? [])
        .map((x) => MatchRosterPlayer.fromJson(x as Map<String, dynamic>))
        .toList(),
    awayRoster: (json['awayRoster'] as List? ?? [])
        .map((x) => MatchRosterPlayer.fromJson(x as Map<String, dynamic>))
        .toList(),
    events: (json['events'] as List? ?? [])
        .map((x) => MatchEvent.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}