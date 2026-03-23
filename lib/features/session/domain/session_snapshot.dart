class SessionSnapshot {
  const SessionSnapshot({
    required this.sessionToken,
    required this.playerId,
    required this.nickname,
    required this.playerStatus,
    required this.currentLobbyId,
    required this.currentBattleId,
    required this.reconnectToken,
  });

  final String sessionToken;
  final String playerId;
  final String nickname;
  final String playerStatus;
  final String? currentLobbyId;
  final String? currentBattleId;
  final String? reconnectToken;

  bool get hasActiveBattle => currentBattleId != null || currentLobbyId != null;

  Map<String, dynamic> toJson() {
    return {
      'sessionToken': sessionToken,
      'playerId': playerId,
      'nickname': nickname,
      'playerStatus': playerStatus,
      'currentLobbyId': currentLobbyId,
      'currentBattleId': currentBattleId,
      'reconnectToken': reconnectToken,
    };
  }

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) {
    return SessionSnapshot(
      sessionToken: json['sessionToken'] as String,
      playerId: json['playerId'] as String,
      nickname: json['nickname'] as String,
      playerStatus: json['playerStatus'] as String,
      currentLobbyId: json['currentLobbyId'] as String?,
      currentBattleId: json['currentBattleId'] as String?,
      reconnectToken: json['reconnectToken'] as String?,
    );
  }
}
