/// Mirrors the `_selectedIndex` values used inside `Checkout`:
///   0 = Delivery, 1 = Self-Pickup, 2 = Carhop, 3 = In-Restaurant
class CheckoutOrderTypeIndex {
  static const int delivery = 0;
  static const int selfPickup = 1;
  static const int carhop = 2;
  static const int inRestaurant = 3;
}

/// Data passed from the reorder flow into Checkout to pre-fill the form.
/// When lat/lng are present, Checkout auto-confirms the delivery pin so the
/// user doesn't have to revisit the map.
class ReorderPayload {
  final int orderTypeIndex;
  final String? deliveryAddressText;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? branchName;
  final String? comment;
  final String? carDetails;

  const ReorderPayload({
    required this.orderTypeIndex,
    this.deliveryAddressText,
    this.deliveryLat,
    this.deliveryLng,
    this.branchName,
    this.comment,
    this.carDetails,
  });
}
