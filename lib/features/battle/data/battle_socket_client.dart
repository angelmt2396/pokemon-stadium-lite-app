import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/i18n/app_strings.dart';
import 'package:pokemon_stadium_lite_app/core/socket/socket_client.dart';
import 'package:pokemon_stadium_lite_app/core/socket/socket_events.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_end_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_status.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_lobby_pokemon.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/battle_state_snapshot.dart';
import 'package:pokemon_stadium_lite_app/features/battle/domain/turn_result_snapshot.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef SearchStatusHandler = void Function(SearchStatusEvent event);
typedef LobbyStatusHandler = void Function(BattleLobbyStatus status);
typedef MatchFoundHandler = void Function(BattleLobbyStatus status);
typedef BattleStartHandler = void Function(BattleStateSnapshot battleState);
typedef BattlePauseHandler = void Function(BattleStateSnapshot battleState);
typedef BattleResumeHandler = void Function(BattleStateSnapshot battleState);
typedef TurnResultHandler = void Function(TurnResultSnapshot result);
typedef BattleEndHandler = void Function(BattleEndSnapshot result);
typedef SimpleSocketStateHandler = void Function();
typedef SocketErrorHandler = void Function(String message);

class SearchStatusEvent {
  const SearchStatusEvent({
    required this.playerId,
    required this.status,
    required this.lobbyId,
    required this.canceled,
  });

  final String? playerId;
  final String status;
  final String? lobbyId;
  final bool canceled;

  factory SearchStatusEvent.fromJson(Map<String, dynamic> json) {
    return SearchStatusEvent(
      playerId: json['playerId'] as String?,
      status: json['status'] as String? ?? 'idle',
      lobbyId: json['lobbyId'] as String?,
      canceled: json['canceled'] as bool? ?? false,
    );
  }
}

class SearchMatchAck {
  const SearchMatchAck({
    required this.playerId,
    required this.reconnectToken,
    required this.lobbyId,
    required this.status,
    required this.lobbyStatus,
  });

  final String playerId;
  final String? reconnectToken;
  final String lobbyId;
  final String status;
  final BattleLobbyStatus lobbyStatus;

  factory SearchMatchAck.fromJson(Map<String, dynamic> json) {
    return SearchMatchAck(
      playerId: json['playerId'] as String,
      reconnectToken: json['reconnectToken'] as String?,
      lobbyId: json['lobbyId'] as String,
      status: json['status'] as String,
      lobbyStatus: BattleLobbyStatus.fromJson(json['lobbyStatus'] as Map<String, dynamic>),
    );
  }
}

class CancelSearchAck {
  const CancelSearchAck({
    required this.playerId,
    required this.canceled,
    required this.lobbyId,
    required this.lobbyStatus,
  });

  final String playerId;
  final bool canceled;
  final String? lobbyId;
  final BattleLobbyStatus? lobbyStatus;

  factory CancelSearchAck.fromJson(Map<String, dynamic> json) {
    return CancelSearchAck(
      playerId: json['playerId'] as String,
      canceled: json['canceled'] as bool? ?? false,
      lobbyId: json['lobbyId'] as String?,
      lobbyStatus: switch (json['lobbyStatus']) {
        final Map<String, dynamic> payload => BattleLobbyStatus.fromJson(payload),
        _ => null,
      },
    );
  }
}

class ReconnectPlayerAck {
  const ReconnectPlayerAck({
    required this.playerId,
    required this.lobbyId,
    required this.lobbyStatus,
    required this.battleState,
  });

  final String playerId;
  final String lobbyId;
  final BattleLobbyStatus lobbyStatus;
  final BattleStateSnapshot? battleState;

  factory ReconnectPlayerAck.fromJson(Map<String, dynamic> json) {
    return ReconnectPlayerAck(
      playerId: json['playerId'] as String,
      lobbyId: json['lobbyId'] as String,
      lobbyStatus: BattleLobbyStatus.fromJson(json['lobbyStatus'] as Map<String, dynamic>),
      battleState: switch (json['battleState']) {
        final Map<String, dynamic> payload => BattleStateSnapshot.fromJson(payload),
        _ => null,
      },
    );
  }
}

class AssignPokemonAck {
  const AssignPokemonAck({
    required this.lobbyId,
    required this.playerId,
    required this.team,
    required this.lobbyStatus,
  });

  final String lobbyId;
  final String playerId;
  final List<BattleLobbyPokemon> team;
  final BattleLobbyStatus lobbyStatus;

  factory AssignPokemonAck.fromJson(Map<String, dynamic> json) {
    return AssignPokemonAck(
      lobbyId: json['lobbyId'] as String,
      playerId: json['playerId'] as String,
      team: ((json['team'] as List<dynamic>? ?? const <dynamic>[]))
          .whereType<Map<String, dynamic>>()
          .map(BattleLobbyPokemon.fromJson)
          .toList(),
      lobbyStatus: BattleLobbyStatus.fromJson(json['lobbyStatus'] as Map<String, dynamic>),
    );
  }
}

class ReadyAck {
  const ReadyAck({
    required this.lobbyId,
    required this.playerId,
    required this.ready,
    required this.lobbyStatus,
    required this.battleStart,
  });

  final String lobbyId;
  final String playerId;
  final bool ready;
  final BattleLobbyStatus lobbyStatus;
  final BattleStateSnapshot? battleStart;

  factory ReadyAck.fromJson(Map<String, dynamic> json) {
    return ReadyAck(
      lobbyId: json['lobbyId'] as String,
      playerId: json['playerId'] as String,
      ready: json['ready'] as bool? ?? false,
      lobbyStatus: BattleLobbyStatus.fromJson(json['lobbyStatus'] as Map<String, dynamic>),
      battleStart: switch (json['battleStart']) {
        final Map<String, dynamic> payload => BattleStateSnapshot.fromJson(payload),
        _ => null,
      },
    );
  }
}

class AttackAck {
  const AttackAck({required this.accepted});

  final bool accepted;

  factory AttackAck.fromJson(Map<String, dynamic> json) {
    return AttackAck(accepted: json['accepted'] as bool? ?? false);
  }
}

class BattleSocketClient {
  BattleSocketClient({
    required String sessionToken,
    required SocketFactory socketFactory,
    required AppStrings strings,
  }) : _socket = socketFactory(sessionToken),
       _strings = strings;

  final io.Socket _socket;
  final AppStrings _strings;

  void bind({
    SimpleSocketStateHandler? onConnected,
    SimpleSocketStateHandler? onDisconnected,
    SocketErrorHandler? onConnectError,
    SearchStatusHandler? onSearchStatus,
    LobbyStatusHandler? onLobbyStatus,
    MatchFoundHandler? onMatchFound,
    BattleStartHandler? onBattleStart,
    BattlePauseHandler? onBattlePause,
    BattleResumeHandler? onBattleResume,
    TurnResultHandler? onTurnResult,
    BattleEndHandler? onBattleEnd,
  }) {
    _socket.off('connect');
    _socket.off('disconnect');
    _socket.off('connect_error');
    _socket.off(SocketEvents.serverSearchStatus);
    _socket.off(SocketEvents.serverLobbyStatus);
    _socket.off(SocketEvents.serverMatchFound);
    _socket.off(SocketEvents.serverBattleStart);
    _socket.off(SocketEvents.serverBattlePause);
    _socket.off(SocketEvents.serverBattleResume);
    _socket.off(SocketEvents.serverTurnResult);
    _socket.off(SocketEvents.serverBattleEnd);

    _socket.on('connect', (_) => onConnected?.call());
    _socket.on('disconnect', (_) => onDisconnected?.call());
    _socket.on('connect_error', (error) {
      onConnectError?.call(error?.toString() ?? _strings.socketConnectFailed);
    });
    _socket.on(SocketEvents.serverSearchStatus, (payload) {
      onSearchStatus?.call(SearchStatusEvent.fromJson(_mapOf(payload)));
    });
    _socket.on(SocketEvents.serverLobbyStatus, (payload) {
      onLobbyStatus?.call(BattleLobbyStatus.fromJson(_mapOf(payload)));
    });
    _socket.on(SocketEvents.serverMatchFound, (payload) {
      onMatchFound?.call(
        BattleLobbyStatus(
          lobbyId: _mapOf(payload)['lobbyId'] as String,
          status: 'waiting',
          players: BattleLobbyStatus.fromJson({
            'lobbyId': _mapOf(payload)['lobbyId'],
            'status': 'waiting',
            'players': _mapOf(payload)['players'],
          }).players,
        ),
      );
    });
    _socket.on(SocketEvents.serverBattleStart, (payload) {
      onBattleStart?.call(BattleStateSnapshot.fromJson(_mapOf(payload)));
    });
    _socket.on(SocketEvents.serverBattlePause, (payload) {
      onBattlePause?.call(BattleStateSnapshot.fromJson(_mapOf(payload)));
    });
    _socket.on(SocketEvents.serverBattleResume, (payload) {
      onBattleResume?.call(BattleStateSnapshot.fromJson(_mapOf(payload)));
    });
    _socket.on(SocketEvents.serverTurnResult, (payload) {
      onTurnResult?.call(TurnResultSnapshot.fromJson(_mapOf(payload)));
    });
    _socket.on(SocketEvents.serverBattleEnd, (payload) {
      onBattleEnd?.call(BattleEndSnapshot.fromJson(_mapOf(payload)));
    });
  }

  Future<void> ensureConnected() async {
    if (_socket.connected) {
      return;
    }

    final completer = Completer<void>();
    late void Function(dynamic) handleConnect;
    late void Function(dynamic) handleError;
    late void Function() cleanup;

    cleanup = () {
      _socket.off('connect', handleConnect);
      _socket.off('connect_error', handleError);
    };

    handleConnect = (dynamic _) {
      cleanup();
      if (!completer.isCompleted) {
        completer.complete();
      }
    };

    handleError = (dynamic error) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(
          Exception(error?.toString() ?? _strings.socketConnectFailed),
        );
      }
    };

    _socket.on('connect', handleConnect);
    _socket.on('connect_error', handleError);
    _socket.connect();

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        cleanup();
        throw Exception(_strings.socketConnectTimeout);
      },
    );
  }

  Future<SearchMatchAck> searchMatch() async {
    final response = await _emitAck(SocketEvents.clientSearchMatch, const {});
    return SearchMatchAck.fromJson(_unwrapAckData(response));
  }

  Future<CancelSearchAck> cancelSearch() async {
    final response = await _emitAck(SocketEvents.clientCancelSearch, const {});
    return CancelSearchAck.fromJson(_unwrapAckData(response));
  }

  Future<ReconnectPlayerAck> reconnectPlayer(String reconnectToken) async {
    final response = await _emitAck(
      SocketEvents.clientReconnectPlayer,
      {'reconnectToken': reconnectToken},
    );
    return ReconnectPlayerAck.fromJson(_unwrapAckData(response));
  }

  Future<AssignPokemonAck> assignPokemon(String lobbyId) async {
    final response = await _emitAck(
      SocketEvents.clientAssignPokemon,
      {'lobbyId': lobbyId},
    );
    return AssignPokemonAck.fromJson(_unwrapAckData(response));
  }

  Future<ReadyAck> markReady(String lobbyId) async {
    final response = await _emitAck(
      SocketEvents.clientReady,
      {'lobbyId': lobbyId},
    );
    return ReadyAck.fromJson(_unwrapAckData(response));
  }

  Future<AttackAck> attack(String battleId) async {
    final response = await _emitAck(
      SocketEvents.clientAttack,
      {'battleId': battleId},
    );
    return AttackAck.fromJson(_unwrapAckData(response));
  }

  void dispose() {
    _socket.dispose();
  }

  Future<Map<String, dynamic>> _emitAck(String event, Map<String, dynamic> payload) async {
    final completer = Completer<Map<String, dynamic>>();

    _socket.emitWithAck(
      event,
      payload,
      ack: (response) {
        if (!completer.isCompleted) {
          completer.complete(_mapOf(response));
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw Exception(_strings.socketAckTimeout),
    );
  }

  Map<String, dynamic> _unwrapAckData(Map<String, dynamic> response) {
    final ok = response['ok'] as bool? ?? false;
    if (!ok) {
      throw Exception(response['message'] as String? ?? _strings.socketGenericError);
    }

    final data = response['data'];
    if (data is! Map) {
      throw Exception(_strings.socketInvalidAck);
    }

    return Map<String, dynamic>.from(data);
  }

  Map<String, dynamic> _mapOf(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    return <String, dynamic>{};
  }
}

final battleSocketClientProvider = Provider.family<BattleSocketClient, String>((ref, sessionToken) {
  final client = BattleSocketClient(
    sessionToken: sessionToken,
    socketFactory: ref.watch(socketFactoryProvider),
    strings: ref.watch(appStringsProvider),
  );

  ref.onDispose(client.dispose);
  return client;
});
