import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

abstract class SessionLocalDataSource {
  Future<SessionSnapshot?> read();
  Future<void> write(SessionSnapshot session);
  Future<void> clear();
}

class SecureSessionLocalDataSource implements SessionLocalDataSource {
  SecureSessionLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;
  static const _sessionKey = 'pokemon_stadium_lite_session';

  @override
  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<SessionSnapshot?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return SessionSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(SessionSnapshot session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sessionLocalDataSourceProvider = Provider<SessionLocalDataSource>((ref) {
  return SecureSessionLocalDataSource(ref.watch(secureStorageProvider));
});
