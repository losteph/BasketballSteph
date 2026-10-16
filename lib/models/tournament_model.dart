// ignore_for_file: constant_identifier_names

class TournamentModel {
  final String id;
  String name;
  List<String> teamIds;
  DateTime createdAt;

  TournamentModel({
    required this.id,
    required this.name,
    required this.teamIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teamIds': teamIds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TournamentModel.fromJson(Map<String, dynamic> json) => TournamentModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    teamIds: List<String>.from(json['teamIds'] as List? ?? []),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}