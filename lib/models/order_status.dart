enum OrderStatus { pending, preparing, ready, completed, cancelled }

class Order {
  final String orderId;
  final String branchName;
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final String orderType;
  final OrderStatus status;
  final DateTime orderTime;
  final String? customerName;
  final String? phoneNumber;
  final String? paymentType;

  Order({
    required this.orderId,
    required this.branchName,
    required this.items,
    required this.totalPrice,
    required this.orderType,
    required this.status,
    required this.orderTime,
    this.customerName,
    this.phoneNumber,
    this.paymentType,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'branchName': branchName,
        'items': items,
        'totalPrice': totalPrice,
        'orderType': orderType,
        'status': status.toString().split('.').last,
        'orderTime': orderTime.toIso8601String(),
        'customerName': customerName,
        'phoneNumber': phoneNumber,
        'paymentType': paymentType,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['orderId'],
        branchName: json['branchName'],
        items: List<Map<String, dynamic>>.from(json['items']),
        totalPrice: (json['totalPrice'] is int)
            ? (json['totalPrice'] as int).toDouble()
            : json['totalPrice'] as double,
        orderType: json['orderType'],
        status: OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
            orElse: () => OrderStatus.pending),
        orderTime: DateTime.parse(json['orderTime']),
        customerName: json['customerName'],
        phoneNumber: json['phoneNumber'],
        paymentType: json['paymentType'],
      );
}
