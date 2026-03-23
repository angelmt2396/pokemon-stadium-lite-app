class BattleEndSnapshot {
  const BattleEndSnapshot({
    required this.battleId,
    required this.lobbyId,
    required this.winnerPlayerId,
    required this.status,
    required this.reason,
    required this.disconnectedPlayerId,
  });

  final String battleId;
  final String lobbyId;
  final String? winnerPlayerId;
  final String status;
  final String? reason;
  final String? disconnectedPlayerId;

  factory BattleEndSnapshot.fromJson(Map<String, dynamic> json) {
    return BattleEndSnapshot(
      battleId: json['battleId'] as String,
      lobbyId: json['lobbyId'] as String,
      winnerPlayerId: json['winnerPlayerId'] as String?,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      disconnectedPlayerId: json['disconnectedPlayerId'] as String?,
    );
  }
}
