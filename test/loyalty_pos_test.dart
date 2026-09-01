import 'package:apploook/models/loyalty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoyaltyPos.transactions', () {
    test('cash only: one cash line, untouched', () {
      final t = LoyaltyPos.transactions(
          cashAmount: 50000, cashbackAmount: 0, cashPaymentTypeId: 2);
      expect(t, [
        {'account_id': 1, 'amount': 50000.0, 'payment_type_id': 2, 'type': 'deposit'},
      ]);
    });

    test('points only: one loyalty line against account 126 / type 12', () {
      final t = LoyaltyPos.transactions(
          cashAmount: 0, cashbackAmount: 50000, cashPaymentTypeId: 2);
      expect(t, [
        {'account_id': 126, 'amount': 50000, 'payment_type_id': 12, 'type': 'deposit'},
      ]);
    });

    test('split: cash line then loyalty line, summing to the order value', () {
      final t = LoyaltyPos.transactions(
          cashAmount: 26000, cashbackAmount: 24000, cashPaymentTypeId: 2);
      expect(t.length, 2);
      expect(t[0]['payment_type_id'], 2);
      expect(t[1]['payment_type_id'], 12);
      expect((t[0]['amount'] as num) + (t[1]['amount'] as num), 50000);
    });

    test('ids from the server override the fallbacks', () {
      final t = LoyaltyPos.transactions(
          cashAmount: 0, cashbackAmount: 1000, cashPaymentTypeId: 2,
          loyaltyAccountId: 999, loyaltyPaymentTypeId: 77);
      expect(t.single['account_id'], 999);
      expect(t.single['payment_type_id'], 77);
    });

    test('zero-value order keeps the historical single zero cash line', () {
      final t = LoyaltyPos.transactions(
          cashAmount: 0, cashbackAmount: 0, cashPaymentTypeId: 2);
      expect(t.single['amount'], 0);
      expect(t.single['payment_type_id'], 2);
    });
  });
}
