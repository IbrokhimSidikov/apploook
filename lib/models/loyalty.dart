/// Loyalty (crystals) models mirroring the sieves-api-v3 `/loyalty` responses.
///
/// The ledger is counted in whole crystals; money figures (payable, soum
/// equivalents) are integer soum. The backend deliberately never sends
/// fractional amounts, so nothing here parses a double.
library;

/// Which crystal price list a customer buys from. A is the regular price.
enum LoyaltyTier {
  a,
  b,
  c;

  static LoyaltyTier parse(dynamic v) {
    switch (v?.toString().toLowerCase()) {
      case 'b':
        return LoyaltyTier.b;
      case 'c':
        return LoyaltyTier.c;
      default:
        return LoyaltyTier.a;
    }
  }

  String get code => name;
}

/// The customer's level from `GET /loyalty/tier`: earned from purchases
/// over a rolling window, with how far the next level is and when the
/// current one lapses without new orders.
class LoyaltyTierStatus {
  /// The level the customer is at now, computed from recent purchases.
  final LoyaltyTier tier;

  /// The level saved on the card, which can lag [tier].
  final LoyaltyTier storedTier;
  final bool isActive;
  final DateTime? lastPurchaseDate;
  final int? daysSinceLastPurchase;

  /// Length of the rolling purchase window, in days.
  final int windowDays;

  /// Null at the top level.
  final LoyaltyTierNext? next;

  /// Null when nothing is due to lapse.
  final LoyaltyTierDowngrade? downgrade;

  const LoyaltyTierStatus({
    required this.tier,
    required this.storedTier,
    required this.isActive,
    this.lastPurchaseDate,
    this.daysSinceLastPurchase,
    required this.windowDays,
    this.next,
    this.downgrade,
  });

  factory LoyaltyTierStatus.fromJson(Map<String, dynamic> json) {
    final window = (json['window'] as Map?)?.cast<String, dynamic>() ?? {};
    final next = (json['next'] as Map?)?.cast<String, dynamic>();
    final downgrade = (json['downgrade'] as Map?)?.cast<String, dynamic>();
    return LoyaltyTierStatus(
      tier: LoyaltyTier.parse(json['tier']),
      storedTier: LoyaltyTier.parse(json['stored_tier'] ?? json['tier']),
      isActive: json['is_active'] == true,
      lastPurchaseDate:
          DateTime.tryParse(json['last_purchase_date']?.toString() ?? ''),
      daysSinceLastPurchase: _int(json['days_since_last_purchase']),
      windowDays: _int(window['days']) ?? 0,
      next: next == null ? null : LoyaltyTierNext.fromJson(next),
      downgrade:
          downgrade == null ? null : LoyaltyTierDowngrade.fromJson(downgrade),
    );
  }

  static int? _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
}

/// What it takes to reach the next level: [remaining] more purchases of at
/// least [minCheckAmount] soum inside the window.
class LoyaltyTierNext {
  final LoyaltyTier tier;
  final int required;
  final int counted;
  final int remaining;
  final int minCheckAmount;

  const LoyaltyTierNext({
    required this.tier,
    required this.required,
    required this.counted,
    required this.remaining,
    required this.minCheckAmount,
  });

  factory LoyaltyTierNext.fromJson(Map<String, dynamic> json) =>
      LoyaltyTierNext(
        tier: LoyaltyTier.parse(json['tier']),
        required: LoyaltyTierStatus._int(json['required']) ?? 0,
        counted: LoyaltyTierStatus._int(json['counted']) ?? 0,
        remaining: LoyaltyTierStatus._int(json['remaining']) ?? 0,
        minCheckAmount: LoyaltyTierStatus._int(json['min_check_amount']) ?? 0,
      );

  /// Share of the way to [tier], 0..1.
  double get progress =>
      required <= 0 ? 1 : (counted / required).clamp(0.0, 1.0);
}

/// The level the customer drops to [on] that date if they stop ordering.
class LoyaltyTierDowngrade {
  final LoyaltyTier tier;
  final DateTime on;

  const LoyaltyTierDowngrade({required this.tier, required this.on});

  static LoyaltyTierDowngrade? fromJson(Map<String, dynamic> json) {
    final on = DateTime.tryParse(json['on']?.toString() ?? '');
    if (on == null) return null;
    return LoyaltyTierDowngrade(tier: LoyaltyTier.parse(json['tier']), on: on);
  }
}

/// How a cart line is settled, as the server names it.
enum LoyaltyPayWith {
  money,
  crystal;

  String get code => name;
}

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

  /// The crystal price list this customer buys from.
  final LoyaltyTier tier;

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
    this.tier = LoyaltyTier.a,
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
        tier: LoyaltyTier.parse(json['tier']),
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

  /// 'crystal' for every program since the migration; 'soum' only on a
  /// backend that has not been converted yet.
  final String unit;

  /// Soum one crystal is worth on the POS payment line.
  final int crystalRateSoum;

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
    this.unit = 'crystal',
    this.crystalRateSoum = 500,
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
        name: json['name']?.toString() ?? 'Crystals',
        unit: json['unit']?.toString() ?? 'crystal',
        crystalRateSoum: _asInt(json['crystal_rate_soum']) > 0
            ? _asInt(json['crystal_rate_soum'])
            : 500,
        earnRatePercent:
            double.tryParse(json['earn_rate_percent']?.toString() ?? '') ?? 0,
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

  bool get isCrystal => unit != 'soum';

  static const fallback = LoyaltyProgram(
    name: 'Crystals',
    unit: 'crystal',
    crystalRateSoum: 500,
    earnRatePercent: 0,
    minRedeemBalance: 0,
    redeemRounding: 1,
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

/// One cart line as the server priced it.
class LoyaltyQuoteLine {
  /// The [CartItem.id] the client sent, echoed back.
  final String lineId;
  final LoyaltyPayWith payWith;
  final int quantity;

  /// Crystals the whole line costs at the customer's tier, or null when it
  /// is not sold for crystals.
  final int? crystalPrice;
  final bool crystalOnly;

  /// Crystals the whole line earns when paid with money.
  final int crystalPoints;
  final int moneyTotal;

  /// `not_sold_for_crystals`, `crystal_only`, `unknown_product`, or null.
  final String? problem;

  const LoyaltyQuoteLine({
    required this.lineId,
    required this.payWith,
    required this.quantity,
    required this.crystalPrice,
    required this.crystalOnly,
    required this.crystalPoints,
    required this.moneyTotal,
    required this.problem,
  });

  factory LoyaltyQuoteLine.fromJson(Map<String, dynamic> json) =>
      LoyaltyQuoteLine(
        lineId: json['line_id']?.toString() ?? '',
        payWith: json['pay_with']?.toString() == 'crystal'
            ? LoyaltyPayWith.crystal
            : LoyaltyPayWith.money,
        quantity: _asInt(json['quantity']),
        crystalPrice: json['crystal_price'] == null
            ? null
            : _asInt(json['crystal_price']),
        crystalOnly: json['crystal_only'] == true,
        crystalPoints: _asInt(json['crystal_points']),
        moneyTotal: _asInt(json['money_total']),
        problem: json['problem']?.toString(),
      );
}

/// Server-computed pricing for one basket. Never compute these numbers on the
/// client: the server is the only place that knows the live balance, the
/// customer's tier and the inventory prices, and it recomputes them again
/// when the hold is created.
class LoyaltyQuote {
  /// 'crystal' or 'soum'.
  final String unit;
  final LoyaltyTier tier;
  final int crystalRateSoum;
  final int subtotal;
  final int deliveryFee;
  final int maxRedeemable;

  /// Crystals leaving the card for this order.
  final int appliedPoints;

  /// [appliedPoints] in soum, for the POS payment line.
  final int appliedSoum;

  /// Soum still to pay with money.
  final int payable;
  final int earnBase;

  /// Crystals this order will earn.
  final int projectedEarn;
  final int balance;
  final int spendable;
  final int pendingBalance;

  /// False for order types the programme excludes (delivery): no earn, no spend.
  final bool orderTypeEligible;

  final List<LoyaltyQuoteLine> lines;

  /// Crystals missing to settle every crystal line; 0 when affordable.
  final int shortfall;

  /// `order_type_not_eligible`, `card_blocked`, `insufficient_crystals`,
  /// `line_problems`, `below_minimum_balance`, `order_too_small`, or null.
  final String? blockedReason;

  const LoyaltyQuote({
    this.unit = 'crystal',
    this.tier = LoyaltyTier.a,
    this.crystalRateSoum = 500,
    required this.subtotal,
    required this.deliveryFee,
    required this.maxRedeemable,
    required this.appliedPoints,
    required this.appliedSoum,
    required this.payable,
    required this.earnBase,
    required this.projectedEarn,
    required this.balance,
    required this.spendable,
    required this.pendingBalance,
    required this.orderTypeEligible,
    this.lines = const [],
    this.shortfall = 0,
    required this.blockedReason,
  });

  /// Legacy soum notion: there is a balance worth offering on this basket.
  bool get canRedeem =>
      orderTypeEligible && maxRedeemable > 0 && blockedReason == null;

  /// True when the server refused to settle the basket as configured, so the
  /// customer must change something before the order can go out.
  bool get isBlocked =>
      blockedReason == 'insufficient_crystals' ||
      blockedReason == 'line_problems' ||
      (blockedReason == 'card_blocked' && appliedPoints > 0);

  LoyaltyQuoteLine? line(String lineId) {
    for (final l in lines) {
      if (l.lineId == lineId) return l;
    }
    return null;
  }

  factory LoyaltyQuote.fromJson(Map<String, dynamic> json) => LoyaltyQuote(
        unit: json['unit']?.toString() ?? 'crystal',
        tier: LoyaltyTier.parse(json['tier']),
        crystalRateSoum: _asInt(json['crystal_rate_soum']) > 0
            ? _asInt(json['crystal_rate_soum'])
            : 500,
        subtotal: _asInt(json['subtotal']),
        deliveryFee: _asInt(json['delivery_fee']),
        maxRedeemable: _asInt(json['max_redeemable']),
        appliedPoints: _asInt(json['applied_points']),
        appliedSoum: json['applied_soum'] == null
            ? _asInt(json['applied_points'])
            : _asInt(json['applied_soum']),
        payable: _asInt(json['payable']),
        earnBase: _asInt(json['earn_base']),
        projectedEarn: _asInt(json['projected_earn']),
        balance: _asInt(json['balance']),
        spendable: _asInt(json['spendable']),
        pendingBalance: _asInt(json['pending_balance']),
        orderTypeEligible: json['order_type_eligible'] != false,
        lines: ((json['lines'] as List?) ?? const [])
            .whereType<Map>()
            .map((l) => LoyaltyQuoteLine.fromJson(l.cast<String, dynamic>()))
            .toList(),
        shortfall: _asInt(json['shortfall']),
        blockedReason: json['redemption_blocked_reason']?.toString(),
      );
}

/// A points reservation held while the order is placed.
class LoyaltyHold {
  final int id;
  final String status;

  /// Crystals reserved.
  final int appliedPoints;

  /// [appliedPoints] in soum: the amount the POS payment line carries.
  final int appliedSoum;
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
    required this.appliedSoum,
    required this.payable,
    required this.projectedEarn,
    required this.expiresAt,
    required this.orderNoteRef,
  });

  factory LoyaltyHold.fromJson(Map<String, dynamic> json) => LoyaltyHold(
        id: _asInt(json['hold_id']),
        status: json['status']?.toString() ?? 'open',
        appliedPoints: _asInt(json['applied_points']),
        appliedSoum: json['applied_soum'] == null
            ? _asInt(json['applied_points'])
            : _asInt(json['applied_soum']),
        payable: _asInt(json['payable']),
        projectedEarn: _asInt(json['projected_earn']),
        expiresAt: _asDate(json['expires_at']),
        orderNoteRef: json['order_note_ref']?.toString() ?? '',
      );
}

enum LoyaltyEntryKind {
  earn,
  redeem,
  reversal,
  refund,
  expiry,
  conversion,
  adjustment
}

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
      case 'conversion':
        return LoyaltyEntryKind.conversion;
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

/// Raised when the server refuses to settle the basket as quoted: the
/// balance moved between the quote and the reservation
/// (`LOYALTY_QUOTE_STALE`), the cached balance is not backed by the ledger
/// (`LOYALTY_BALANCE_UNBACKED`), or a line cannot be paid the way it is set
/// (`LOYALTY_LINE_PROBLEM`). Carries the fresh quote to re-render with, and
/// the server's code and message so the reason is visible in the log.
class LoyaltyQuoteStaleException implements Exception {
  final LoyaltyQuote? quote;
  final String? code;
  final String? message;
  LoyaltyQuoteStaleException(this.quote, {this.code, this.message});

  bool get isUnbacked => code == 'LOYALTY_BALANCE_UNBACKED';
  bool get isLineProblem => code == 'LOYALTY_LINE_PROBLEM';

  @override
  String toString() =>
      'LoyaltyQuoteStaleException(${code ?? 'unknown'}: ${message ?? ''})';
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
  /// [cashbackAmount] is the crystal payment in soum (crystals x rate, the
  /// hold's `applied_soum`). The order value is cash plus that line; crystal
  /// lines reach the POS priced at their soum equivalent so the two agree.
  /// Cash first, then the crystal line, so a receipt reads the way a cashier
  /// expects:
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
