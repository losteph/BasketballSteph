// ignore_for_file: constant_identifier_names

class TeamPlayerEntry {
  final String playerId;
  bool isStarter;
  String? customNum;

  TeamPlayerEntry({
    required this.playerId,
    this.isStarter = false,
    this.customNum,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'isStarter': isStarter,
    'customNum': customNum,
  };

  factory TeamPlayerEntry.fromJson(Map<String, dynamic> json) => TeamPlayerEntry(
    playerId: json['playerId'] as String? ?? '',
    isStarter: json['isStarter'] as bool? ?? false,
    customNum: json['customNum'] as String?,
  );
}

class TeamModel {
  final String id;
  String name;
  int colorValue;
  List<TeamPlayerEntry> roster;

  TeamModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.roster,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'roster': roster.map((e) => e.toJson()).toList(),
  };

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Nuova Squadra',
    colorValue: json['colorValue'] as int? ?? 0xFF3B82F6,
    roster: (json['roster'] as List? ?? [])
        .map((x) => TeamPlayerEntry.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}