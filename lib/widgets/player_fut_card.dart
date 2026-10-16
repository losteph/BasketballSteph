import 'package:flutter/material.dart';
import '../models/player_model.dart';

class PlayerFutCard extends StatelessWidget {
  final PlayerModel player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlayerFutCard({
    super.key,
    required this.player,
    required this.onEdit,
    required this.onDelete,
  });

  LinearGradient _getTierGradient(CardTier tier) {
    switch (tier) {
      case CardTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFEAB308), Color(0xFFCA8A04), Color(0xFF854D0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardTier.silver:
        return const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardTier.bronze:
        return const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFF92400E), Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ovr = player.ovrData;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF263559)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 54,
            decoration: BoxDecoration(
              gradient: _getTierGradient(ovr.tier),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${ovr.numeric}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                Text(
                  ovr.letter,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: player.roleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: player.roleColor, width: 1),
                      ),
                      child: Text(
                        player.role.name,
                        style: TextStyle(
                          color: player.roleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: PlayerModel.statDefs.map((def) {
                    final val = player.stats[def['id']] ?? 'B';
                    return Text(
                      '${def['label']}: $val',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF3B82F6)),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}