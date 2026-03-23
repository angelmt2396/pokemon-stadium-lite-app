import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_stadium_lite_app/app/app.dart';
import 'package:pokemon_stadium_lite_app/features/session/data/session_local_data_source.dart';
import 'package:pokemon_stadium_lite_app/features/session/domain/session_snapshot.dart';

class InMemorySessionLocalDataSource implements SessionLocalDataSource {
  SessionSnapshot? _session;

  @override
  Future<void> clear() async {
    _session = null;
  }

  @override
  Future<SessionSnapshot?> read() async => _session;

  @override
  Future<void> write(SessionSnapshot session) async {
    _session = session;
  }
}

void main() {
  testWidgets('shows the login entrypoint when there is no persisted session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionLocalDataSourceProvider.overrideWithValue(InMemorySessionLocalDataSource()),
        ],
        child: const PokemonStadiumLiteApp(),
      ),
    );

    for (var index = 0; index < 20; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Entrar al juego').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('PokeAlbo'), findsOneWidget);
    expect(find.text('Entrar al juego'), findsOneWidget);
  });
}
