import 'package:bite/features/home/presentation/widgets/daily_chest_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final premium in [false, true]) {
    for (final size in [const Size(320, 640), const Size(390, 844)]) {
      testWidgets(
        'chest card fits ${size.width.toInt()}px (premium: $premium)',
        (tester) async {
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DailyChestOverlay(
                  isPremium: premium,
                  signedIn: false,
                  onClaimed: (_) {},
                  onClose: () {},
                  onUpgradePremium: () {},
                  onSignIn: () {},
                ),
              ),
            ),
          );
          for (var i = 0; i < 15; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          // A RenderFlex overflow would surface here.
          expect(tester.takeException(), isNull);
          expect(find.text('Daily Reward Earned'), findsOneWidget);
        },
      );
    }
  }
}
