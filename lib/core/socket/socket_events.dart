class SocketEvents {
  const SocketEvents._();

  static const clientSearchMatch = 'search_match';
  static const clientCancelSearch = 'cancel_search';
  static const clientReconnectPlayer = 'reconnect_player';
  static const clientAssignPokemon = 'assign_pokemon';
  static const clientReady = 'ready';
  static const clientAttack = 'attack';

  static const serverSearchStatus = 'search_status';
  static const serverMatchFound = 'match_found';
  static const serverLobbyStatus = 'lobby_status';
  static const serverBattleStart = 'battle_start';
  static const serverBattlePause = 'battle_pause';
  static const serverTurnResult = 'turn_result';
  static const serverBattleEnd = 'battle_end';
}
