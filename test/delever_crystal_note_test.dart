import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/delever_crystal_note.dart';
import 'package:flutter_test/flutter_test.dart';

class _Product {
  const _Product(this.uuid);
  final String? uuid;
  final bool isCrystalOnly = false;
}

const _a = 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa';
const _b = 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb';

CartItem _line(String? uuid, int quantity, {bool crystals = true}) => CartItem(
      product: _Product(uuid),
      quantity: quantity,
      payWithCrystals: crystals,
    );

void main() {
  group('DeleverCrystalNote.compose', () {
    test('keys first, then the customer comment', () {
      expect(
        DeleverCrystalNote.compose(
          crystalLines: [_line(_a, 2), _line(_b, 1)],
          holdRef: 'loyalty_ref:684;',
          comment: 'iltimos tezroq',
        ),
        'crystal_items:$_a:2,$_b:1;\nloyalty_ref:684;\niltimos tezroq',
      );
    });

    test('no crystal lines: an earn-only hold sends only loyalty_ref', () {
      expect(
        DeleverCrystalNote.compose(
          crystalLines: const [],
          holdRef: 'loyalty_ref:684;',
          comment: 'iltimos tezroq',
        ),
        'loyalty_ref:684;\niltimos tezroq',
      );
    });

    test('no hold: no keys at all', () {
      expect(
        DeleverCrystalNote.compose(
          crystalLines: [_line(_a, 2)],
          holdRef: null,
          comment: 'iltimos tezroq',
        ),
        'iltimos tezroq',
      );
    });

    test('keys typed by the customer are dropped', () {
      expect(
        DeleverCrystalNote.compose(
          crystalLines: const [],
          holdRef: null,
          comment: 'crystal_items:$_a:9; LOYALTY_REF:1; salom',
        ),
        'salom',
      );
    });
  });

  group('DeleverCrystalNote.crystalItemsKey', () {
    test('adds up lines of one product and has no spaces', () {
      expect(
        DeleverCrystalNote.crystalItemsKey([_line(_a, 2), _line(_a, 3)]),
        'crystal_items:$_a:5;',
      );
    });

    test('empty when no line has a product id', () {
      expect(DeleverCrystalNote.crystalItemsKey([_line(null, 1)]), '');
    });
  });

  test('crystalLinesFirst keeps the order inside each group', () {
    final money = _line(_a, 1, crystals: false);
    final crystal = _line(_a, 2);
    final bag = _line(_b, 1, crystals: false);
    expect(
      DeleverCrystalNote.crystalLinesFirst([money, crystal, bag]),
      [crystal, money, bag],
    );
  });
}
