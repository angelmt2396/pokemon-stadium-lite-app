import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

enum SessionStatus {
  booting,
  unauthenticated,
  authenticated,
}

class SessionState {
  const SessionState({
    required this.status,
    required this.session,
    required this.errorMessage,
  });

  const SessionState.booting()
      : status = SessionStatus.booting,
        session = null,
        errorMessage = null;

  const SessionState.unauthenticated({this.errorMessage})
      : status = SessionStatus.unauthenticated,
        session = null;

  const SessionState.authenticated(this.session)
      : status = SessionStatus.authenticated,
        errorMessage = null;

  final SessionStatus status;
  final SessionSnapshot? session;
  final String? errorMessage;

  SessionState copyWith({
    SessionStatus? status,
    SessionSnapshot? session,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
