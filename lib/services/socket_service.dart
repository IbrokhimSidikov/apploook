import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void initSocket() {
    print('🔌 Initializing socket connection...');
    socket = IO.io('https://testsocket.sievesapp.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
    });

    socket.onConnect((_) {
      print('✅ Socket connected successfully');
      print('🔗 Socket ID: ${socket.id}');
    });

    socket.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    socket.onError((error) {
      print('⚠️ Socket error: $error');
    });

    socket.onReconnect((_) {
      print('🔄 Socket reconnected');
    });

    socket.onReconnectAttempt((attempt) {
      print('⏳ Reconnection attempt #$attempt');
    });

    print('🚀 Attempting socket connection...');
    socket.connect();
  }

  void notifyArrival(int orderId) {
    print('📤 Emitting drive-through:customer-arrived event');
    print('📦 Payload: {"orderId": $orderId}');

    socket.emit('drive-through:customer-arrived', {'orderId': orderId});

    if (socket.connected) {
      print('✅ Event emitted successfully (socket is connected)');
    } else {
      print('⚠️ Warning: Socket is not connected while trying to emit event');
    }
  }
}
