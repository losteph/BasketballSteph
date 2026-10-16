// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum PlayerRole {
  PG, // Arancione
  SG, // Blu/Azzurro
  SF, // Verde
  PF, // Viola
  C,  // Rosso
}

enum CardTier {
  gold,
  silver,
  bronze,
}

class PlayerOvrData {
  final int numeric;
  final String letter;
  final CardTier tier;

  PlayerOvrData({
    required this.numeric,
    required this.letter,
    required this.tier,
  });
}

class PlayerModel {
  final String id;
  String name;
  PlayerRole role;
  Map<String, String> stats;

  PlayerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.stats,
  });

  Color get roleColor {
    switch (role) {
      case PlayerRole.PG:
        return const Color(0xFFF97316); // Arancione
      case PlayerRole.SG:
        return const Color(0xFF38BDF8); // Blu/Azzurro
      case PlayerRole.SF:
        return const Color(0xFF10B981); // Verde
      case PlayerRole.PF:
        return const Color(0xFF8B5CF6); // Viola
      case PlayerRole.C:
        return const Color(0xFFEF4444); // Rosso
    }
  }

  static const List<Map<String, String>> statDefs = [
    {'id': 'tir', 'label': 'TIR'},
    {'id': 'pas', 'label': 'PAS'},
    {'id': 'dri', 'label': 'DRI'},
    {'id': 'dif', 'label': 'DIF'},
    {'id': 'rim', 'label': 'RIM'},
    {'id': 'fis', 'label': 'FIS'},
  ];

  static const Map<String, int> gradeValues = {
    'A+': 99, 'A': 92, 'A-': 87,
    'B+': 82, 'B': 77, 'B-': 72,
    'C+': 67, 'C': 62, 'C-': 55,
  };

  static const Map<PlayerRole, Map<String, double>> roleWeights = {
    PlayerRole.PG: {'pas': 0.30, 'dri': 0.25, 'tir': 0.20, 'dif': 0.10, 'fis': 0.10, 'rim': 0.05},
    PlayerRole.SG: {'tir': 0.35, 'dri': 0.20, 'pas': 0.15, 'dif': 0.15, 'fis': 0.10, 'rim': 0.05},
    PlayerRole.SF: {'tir': 0.25, 'dif': 0.20, 'fis': 0.20, 'dri': 0.15, 'rim': 0.10, 'pas': 0.10},
    PlayerRole.PF: {'rim': 0.30, 'fis': 0.25, 'dif': 0.20, 'tir': 0.15, 'pas': 0.05, 'dri': 0.05},
    PlayerRole.C:  {'rim': 0.35, 'dif': 0.25, 'fis': 0.25, 'tir': 0.10, 'pas': 0.03, 'dri': 0.02},
  };

  PlayerOvrData get ovrData {
    if (stats.isEmpty) return PlayerOvrData(numeric: 70, letter: 'B-', tier: CardTier.silver);
    final weights = roleWeights[role] ?? roleWeights[PlayerRole.PG]!;
    
    double sum = 0.0;
    double totalWeight = 0.0;

    weights.forEach((statKey, weight) {
      final grade = stats[statKey] ?? 'B';
      final val = gradeValues[grade] ?? 75;
      sum += val * weight;
      totalWeight += weight;
    });

    final numVal = totalWeight > 0 ? (sum / totalWeight).round() : 70;
    
    String lbl = 'B-';
    if (numVal >= 95) {
      lbl = 'A+';
    } else if (numVal >= 90) { lbl = 'A'; }
    else if (numVal >= 85) {lbl = 'A-'; }
    else if (numVal >= 80) {lbl = 'B+';}
    else if (numVal >= 75) {lbl = 'B';}
    else if (numVal >= 70) {lbl = 'B-';}
    else if (numVal >= 66) {lbl = 'C+';}
    else if (numVal >= 60) {lbl = 'C';}
    else { lbl = 'C-';}

    CardTier tier = CardTier.bronze;
    if (numVal >= 80) {
      tier = CardTier.gold;
    } else if (numVal >= 70) {
      tier = CardTier.silver;
    }

    return PlayerOvrData(numeric: numVal, letter: lbl, tier: tier);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'stats': stats,
  };

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    role: PlayerRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => PlayerRole.PG,
    ),
    stats: Map<String, String>.from(json['stats'] as Map? ?? {}),
  );
}
