/// Loyalty (cashback) models mirroring the sieves-api-v3 `/loyalty` responses.
///
/// Every amount is an integer number of soum. The backend deliberately never
/// sends fractional money, so nothing here parses a double.
library;

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

/// The customer's card as the server sees it.
class LoyaltyCard {
  final String number;
  final String status;

  /// Posted balance. Points reserved by an open checkout are still counted
  /// here, so use [spendable] anywhere the customer is about to spend.
  final int balance;

  /// Earned but not yet spendable - the order has not been delivered yet.
  final int pendingBalance;

  final int heldBalance;
  final int spendable;
  final int lifetimeEarned;
  final int lifetimeRedeemed;

  const LoyaltyCard({
    required this.number,
    required this.status,
    required this.balance,
    required this.pendingBalance,
    required this.heldBalance,
    required this.spendable,
    required this.lifetimeEarned,
    required this.lifetimeRedeemed,
  });

  bool get isActive => status == 'active';

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
        number: json['number']?.toString() ?? '',
        status: json['status']?.toString() ?? 'active',
        balance: _asInt(json['balance']),
        pendingBalance: _asInt(json['pending_balance']),
        heldBalance: _asInt(json['held_balance']),
        spendable: _asInt(json['spendable']),
        lifetimeEarned: _asInt(json['lifetime_earned']),
        lifetimeRedeemed: _asInt(json['lifetime_redeemed']),
      );

  static const empty = LoyaltyCard(
    number: '',
    status: 'active',
    balance: 0,
    pendingBalance: 0,
    heldBalance: 0,
    spendable: 0,
    lifetimeEarned: 0,
    lifetimeRedeemed: 0,
  );
}

/// Program terms in force. Driven from the server so a campaign rate change
/// reaches the app without a release.
class LoyaltyProgram {
  final String name;
  final double earnRatePercent;
  final int minRedeemBalance;
  final int redeemRounding;
  final double maxRedeemPercent;
  final bool redeemCoversDeliveryFee;
  final bool earnOnDeliveryFee;
  final int? pointsExpireDays;

  /// POS order type ids that earn cashback (1 in-restaurant, 2 self-pickup,
  /// 3 delivery, 8 carhop). Server-driven, so the app's wording follows the
  /// config instead of hardcoding which types qualify.
  final List<int> eligibleOrderTypeIds;

  /// POS account and payment type a points payment is booked against.
  final int posAccountId;
  final int posPaymentTypeId;

  const LoyaltyProgram({
    required this.name,
    required this.earnRatePercent,
    required this.minRedeemBalance,
    required this.redeemRounding,
    required this.maxRedeemPercent,
    required this.redeemCoversDeliveryFee,
    required this.earnOnDeliveryFee,
    required this.pointsExpireDays,
    required this.eligibleOrderTypeIds,
    required this.posAccountId,
    required this.posPaymentTypeId,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) => LoyaltyProgram(
        name: json['name']?.toString() ?? 'Cashback',
        earnRatePercent:
            double.tryParse(json['earn_rate_percent']?.toString() ?? '') ?? 5,
        minRedeemBalance: _asInt(json['min_redeem_balance']),
        redeemRounding: _asInt(json['redeem_rounding']) == 0
            ? 1
            : _asInt(json['redeem_rounding']),
        maxRedeemPercent:
            double.tryParse(json['max_redeem_percent']?.toString() ?? '') ?? 100,
        redeemCoversDeliveryFee: json['redeem_covers_delivery_fee'] == true,
        earnOnDeliveryFee: json['earn_on_delivery_fee'] == true,
        pointsExpireDays: json['points_expire_days'] == null
            ? null
            : _asInt(json['points_expire_days']),
        eligibleOrderTypeIds:
            ((json['eligible_order_type_ids'] as List?) ?? const [])
                .map(_asInt)
                .where((id) => id > 0)
                .toList(),
        posAccountId: _asInt(json['pos_account_id']) > 0
            ? _asInt(json['pos_account_id'])
            : LoyaltyPos.defaultAccountId,
        posPaymentTypeId: _asInt(json['pos_payment_type_id']) > 0
            ? _asInt(json['pos_payment_type_id'])
            : LoyaltyPos.defaultPaymentTypeId,
      );

  static const fallback = LoyaltyProgram(
    name: 'Cashback',
    earnRatePercent: 5,
    minRedeemBalance: 5000,
    redeemRounding: 1000,
    maxRedeemPercent: 100,
    redeemCoversDeliveryFee: false,
    earnOnDeliveryFee: false,
    pointsExpireDays: 365,
    eligibleOrderTypeIds: [1, 2, 8],
    posAccountId: LoyaltyPos.defaultAccountId,
    posPaymentTypeId: LoyaltyPos.defaultPaymentTypeId,
  );
}

class LoyaltySummary {
  final LoyaltyCard card;
  final LoyaltyProgram program;

  const LoyaltySummary({required this.card, required this.program});

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) => LoyaltySummary(
        card: LoyaltyCard.fromJson(
            (json['card'] as Map?)?.cast<String, dynamic>() ?? const {}),
        program: LoyaltyProgram.fromJson(
            (json['program'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );

  static const empty =
      LoyaltySummary(card: LoyaltyCard.empty, program: LoyaltyProgram.fallback);
}

/// Server-computed pricing for one basket. Never compute these numbers on the
/// client: the server is the only place that knows the live balance and the
/// program rules, and it recomputes them again when the hold is created.
class LoyaltyQuote {
  final int subtotal;
  final int deliveryFee;
  final int maxRedeemable;
  final int appliedPoints;
  final int payable;
  final int earnBase;
  final int projectedEarn;
  final int balance;
  final int spendable;
  final int pendingBalance;

  /// False for order types the programme excludes (delivery): no earn, no spend.
  final bool orderTypeEligible;

  /// `order_type_not_eligible`, `below_minimum_balance`, `order_too_small`,
  /// `card_blocked`, or null.
  final String? blockedReason;

  const LoyaltyQuote({
    required this.subtotal,
    required this.deliveryFee,
    required this.maxRedeemable,
    required this.appliedPoints,
    required this.payable,
    required this.earnBase,
    required this.projectedEarn,
    required this.balance,
    required this.spendable,
    required this.pendingBalance,
    required this.orderTypeEligible,
    required this.blockedReason,
  });

  bool get canRedeem =>
      orderTypeEligible && maxRedeemable > 0 && blockedReason == null;

  factory LoyaltyQuote.fromJson(Map<String, dynamic> json) => LoyaltyQuote(
        subtotal: _asInt(json['subtotal']),
        deliveryFee: _asInt(json['delivery_fee']),
        maxRedeemable: _asInt(json['max_redeemable']),
        appliedPoints: _asInt(json['applied_points']),
        payable: _asInt(json['payable']),
        earnBase: _asInt(json['earn_base']),
        projectedEarn: _asInt(json['projected_earn']),
        balance: _asInt(json['balance']),
        spendable: _asInt(json['spendable']),
        pendingBalance: _asInt(json['pending_balance']),
        orderTypeEligible: json['order_type_eligible'] != false,
        blockedReason: json['redemption_blocked_reason']?.toString(),
      );
}

/// A points reservation held while the order is placed.
class LoyaltyHold {
  final int id;
  final String status;
  final int appliedPoints;
  final int payable;
  final int projectedEarn;
  final DateTime? expiresAt;

  /// Must be appended to the order comment. It is the only link the settlement
  /// job has between the order that comes back from Delever and this hold.
  final String orderNoteRef;

  const LoyaltyHold({
    required this.id,
    required this.status,
    required this.appliedPoints,
    required this.payable,
    required this.projectedEarn,
    required this.expiresAt,
    required this.orderNoteRef,
  });

  factory LoyaltyHold.fromJson(Map<String, dynamic> json) => LoyaltyHold(
        id: _asInt(json['hold_id']),
        status: json['status']?.toString() ?? 'open',
        appliedPoints: _asInt(json['applied_points']),
        payable: _asInt(json['payable']),
        projectedEarn: _asInt(json['projected_earn']),
        expiresAt: _asDate(json['expires_at']),
        orderNoteRef: json['order_note_ref']?.toString() ?? '',
      );
}

enum LoyaltyEntryKind { earn, redeem, reversal, refund, expiry, adjustment }

/// One row of the wallet history feed.
class LoyaltyTransaction {
  final int id;
  final String type;
  final String status;

  /// Signed: positive credited the customer, negative debited them.
  final int amount;
  final int? orderId;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? note;

  const LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.orderId,
    required this.createdAt,
    required this.expiresAt,
    required this.note,
  });

  bool get isPending => status == 'pending';
  bool get isReversed => status == 'reversed';
  bool get isCredit => amount > 0;

  LoyaltyEntryKind get kind {
    switch (type) {
      case 'earn':
        return LoyaltyEntryKind.earn;
      case 'redeem':
        return LoyaltyEntryKind.redeem;
      case 'earn_reversal':
        return LoyaltyEntryKind.reversal;
      case 'redeem_refund':
        return LoyaltyEntryKind.refund;
      case 'expire':
        return LoyaltyEntryKind.expiry;
      default:
        return LoyaltyEntryKind.adjustment;
    }
  }

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        id: _asInt(json['id']),
        type: json['type']?.toString() ?? 'adjust',
        status: json['status']?.toString() ?? 'posted',
        amount: _asInt(json['amount']),
        orderId: json['order_id'] == null ? null : _asInt(json['order_id']),
        createdAt: _asDate(json['created_at']),
        expiresAt: _asDate(json['expires_at']),
        note: json['note']?.toString(),
      );
}

/// Raised when the server rejects a hold because the balance moved between
/// the quote and the reservation. Carries the fresh quote to re-render with.
class LoyaltyQuoteStaleException implements Exception {
  final LoyaltyQuote? quote;
  LoyaltyQuoteStaleException(this.quote);

  @override
  String toString() => 'LoyaltyQuoteStaleException';
}

/// Raised when the session token is missing, expired or revoked.
class LoyaltySessionExpiredException implements Exception {
  @override
  String toString() => 'LoyaltySessionExpiredException';
}

/// How a points payment appears on the POS order.
class LoyaltyPos {
  /// Fallbacks if the server does not send them - the values agreed with
  /// accounting for the cashback account and payment type.
  static const int defaultAccountId = 126;
  static const int defaultPaymentTypeId = 12;

  /// Builds the `transactions` array for a Sieves order.
  ///
  /// The order keeps its full [value]; what changes is how that value was
  /// settled. Cash first, then the points line, so a receipt reads the way a
  /// cashier expects:
  ///
  ///   cash only     -> [cash: total]
  ///   points only   -> [points: total]
  ///   split         -> [cash: paid, points: redeemed]
  ///
  /// A zero-value order still gets a single zero cash line, matching what the
  /// POS has always received.
  static List<Map<String, dynamic>> transactions({
    required double cashAmount,
    required int cashbackAmount,
    required int cashPaymentTypeId,
    int cashAccountId = 1,
    int loyaltyAccountId = defaultAccountId,
    int loyaltyPaymentTypeId = defaultPaymentTypeId,
  }) {
    final lines = <Map<String, dynamic>>[];
    if (cashAmount > 0 || cashbackAmount <= 0) {
      lines.add({
        'account_id': cashAccountId,
        'amount': cashAmount,
        'payment_type_id': cashPaymentTypeId,
        'type': 'deposit',
      });
    }
    if (cashbackAmount > 0) {
      lines.add({
        'account_id': loyaltyAccountId,
        'amount': cashbackAmount,
        'payment_type_id': loyaltyPaymentTypeId,
        'type': 'deposit',
      });
    }
    return lines;
  }
}
