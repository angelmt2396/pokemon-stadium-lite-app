import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemon_stadium_lite_app/core/config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef SocketFactory = io.Socket Function(String sessionToken);

io.Socket defaultSocketFactory(String sessionToken) {
  return io.io(
    AppConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setTimeout(5000)
        .setAuth({'sessionToken': sessionToken}).build(),
  );
}

final socketFactoryProvider = Provider<SocketFactory>((ref) {
  return defaultSocketFactory;
});
