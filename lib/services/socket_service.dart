// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:apploook/models/order_status.dart';

// class SocketService {
//   WebSocketChannel? _channel;
//   final ValueNotifier<Order?> orderUpdate = ValueNotifier(null);
//   String? _trackingOrderId;

//   void initSocket(int branchId, String orderId) {
//     _trackingOrderId = orderId;
//     final wsUrl = Uri.parse('wss://socket.sievesapp.com/orders/$branchId');
//     _channel = WebSocketChannel.connect(wsUrl);

//     _channel?.stream.listen(
//       (message) {
//         final data = json.decode(message);

//         // Only process updates for the specific order we're tracking
//         if (data['orderId'] == _trackingOrderId) {
//           try {
//             final order = Order.fromJson(data);
//             orderUpdate.value = order;
//           } catch (e) {
//             print('Error parsing order update: $e');
//           }
//         }
//       },
//       onError: (error) {
//         print('WebSocket Error: $error');
//       },
//       onDone: () {
//         print('WebSocket Connection Closed');
//       },
//     );
//   }

//   void sendMessage(String message) {
//     if (_channel != null) {
//       _channel!.sink.add(message);
//     }
//   }

//   void dispose() {
//     _channel?.sink.close();
//     _channel = null;
//     _trackingOrderId = null;
//   }
// }
