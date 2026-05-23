/// Server-side order type IDs returned by the Sieves history API.
/// Kept in one place so mapping between domains stays consistent.
class HistoryOrderType {
  static const int delivery = 1;
  static const int carhop = 2;
  static const int selfPickup = 3;
  static const int dineIn = 4;
}

/// One line item from a historical order, as it lived on the server.
/// Identifiers are intentionally permissive — different Sieves endpoints
/// return product IDs under different keys, and the menu may not contain
/// every historical product anymore.
class LastOrderItem {
  /// All Delever-style UUIDs this inventory row maps to. One kitchen item
  /// can be sold as several menu products (different sizes / regions), so
  /// matching needs to try every candidate.
  final List<String> productUuids;
  final String name;
  final int quantity;
  final double actualPrice;
  final List<LastOrderItemModifier> modifiers;

  const LastOrderItem({
    required this.name,
    required this.quantity,
    required this.actualPrice,
    this.productUuids = const [],
    this.modifiers = const [],
  });

  /// Convenience for callers that only care about a single identifier.
  String? get productUuid =>
      productUuids.isNotEmpty ? productUuids.first : null;

  factory LastOrderItem.fromJson(Map<String, dynamic> json) {
    final modifiersJson = json['modifiers'] as List<dynamic>? ?? const [];
    // Prefer the Delever-style uuids: that's what MenuService stores as
    // Product.uuid. `product_id` here is the numeric t_inventory.id and
    // won't match the menu, so it's only a last-ditch fallback.
    return LastOrderItem(
      productUuids: _collectUuids(json),
      name: (json['name'] ?? json['product_name'] ?? '').toString(),
      quantity: _asInt(json['quantity']) ?? 1,
      actualPrice: _asDouble(json['actual_price'] ?? json['price']) ?? 0,
      modifiers: modifiersJson
          .whereType<Map<String, dynamic>>()
          .map(LastOrderItemModifier.fromJson)
          .toList(),
    );
  }
}

List<String> _collectUuids(Map<String, dynamic> json) {
  final out = <String>[];
  void addAll(dynamic raw) {
    if (raw == null) return;
    if (raw is List) {
      for (final v in raw) {
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty && !out.contains(s)) out.add(s);
      }
    } else {
      // Accept either a single value or a comma-separated string.
      for (final part in raw.toString().split(',')) {
        final s = part.trim();
        if (s.isNotEmpty && !out.contains(s)) out.add(s);
      }
    }
  }

  addAll(json['product_uuids']);
  addAll(json['productUuids']);
  addAll(json['product_uuid']);
  addAll(json['productUuid']);
  if (out.isEmpty) {
    final nested = json['product'];
    if (nested is Map) {
      addAll(nested['uuid']);
      addAll(nested['id']);
    }
  }
  if (out.isEmpty) {
    addAll(json['product_id']);
    addAll(json['productId']);
  }
  return out;
}

class LastOrderItemModifier {
  final String name;
  final int quantity;
  final List<String> productUuids;

  const LastOrderItemModifier({
    required this.name,
    required this.quantity,
    this.productUuids = const [],
  });

  factory LastOrderItemModifier.fromJson(Map<String, dynamic> json) {
    return LastOrderItemModifier(
      name: (json['name'] ?? '').toString(),
      quantity: _asInt(json['quantity']) ?? 1,
      productUuids: _collectUuids(json),
    );
  }
}

/// A historical order, normalized for the reorder feature.
class LastOrder {
  final int id;
  final int orderTypeId;
  final String? statusName;
  final String? branchName;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? note;
  final double totalValue;
  final DateTime? placedAt;
  final List<LastOrderItem> items;

  const LastOrder({
    required this.id,
    required this.orderTypeId,
    required this.items,
    required this.totalValue,
    this.statusName,
    this.branchName,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.note,
    this.placedAt,
  });

  bool get isDelivery => orderTypeId == HistoryOrderType.delivery;

  /// Only completed orders are eligible for reorder. Pending / cancelled
  /// orders show up in history but aren't useful starting points.
  bool get isReorderEligible {
    final s = (statusName ?? '').trim().toLowerCase();
    return s == 'delivered' || s == 'closed';
  }

  factory LastOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List<dynamic>? ?? const [];
    return LastOrder(
      id: _asInt(json['id']) ?? 0,
      orderTypeId: _asInt(json['order_type_id']) ?? HistoryOrderType.delivery,
      statusName: json['status_name']?.toString(),
      branchName: json['branch_name']?.toString(),
      deliveryAddress: _firstString(json, const [
        'delivery_address',
        'address',
        'client_address',
      ]),
      deliveryLat: _asDouble(json['delivery_lat'] ?? json['lat']),
      deliveryLng: _asDouble(json['delivery_lng'] ?? json['lng']),
      note: _firstString(json, const ['note', 'comment']),
      totalValue: _asDouble(json['value']) ?? 0,
      placedAt: _parseDate(json['time']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(LastOrderItem.fromJson)
          .toList(),
    );
  }
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
