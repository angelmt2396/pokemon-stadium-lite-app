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

  SessionSnapshot copyWith({
    String? sessionToken,
    String? playerId,
    String? nickname,
    String? playerStatus,
    String? currentLobbyId,
    bool clearCurrentLobbyId = false,
    String? currentBattleId,
    bool clearCurrentBattleId = false,
    String? reconnectToken,
    bool clearReconnectToken = false,
  }) {
    return SessionSnapshot(
      sessionToken: sessionToken ?? this.sessionToken,
      playerId: playerId ?? this.playerId,
      nickname: nickname ?? this.nickname,
      playerStatus: playerStatus ?? this.playerStatus,
      currentLobbyId: clearCurrentLobbyId ? null : currentLobbyId ?? this.currentLobbyId,
      currentBattleId: clearCurrentBattleId ? null : currentBattleId ?? this.currentBattleId,
      reconnectToken: clearReconnectToken ? null : reconnectToken ?? this.reconnectToken,
    );
  }

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
