import 'package:apploook/features/crystal_shop/presentation/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CrystalIcon renders Kristal.svg once and shares the bitmap',
      (tester) async {
    await tester.runAsync(() => CrystalIcon.precache());

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        CrystalIcon(width: 24, height: 24),
        CrystalIcon(width: 54, height: 54),
      ]),
    ));
    await tester.pump();

    final images = tester.widgetList<RawImage>(find.byType(RawImage)).toList();
    expect(images, hasLength(2));
    final image = images.first.image!;
    // Same bitmap instance for every icon, rendered at 384px long side.
    expect(identical(image, images.last.image), isTrue);
    expect(image.width == 384 || image.height == 384, isTrue);
  });
}
