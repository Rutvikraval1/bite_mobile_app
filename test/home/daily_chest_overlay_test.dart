import 'package:bite/features/home/presentation/widgets/daily_chest_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required bool premium,
    required VoidCallback onUpgrade,
  }) => MaterialApp(
    home: Scaffold(
      body: DailyChestOverlay(
        isPremium: premium,
        signedIn: false,
        onClaimed: (_) {},
        onClose: () {},
        onUpgradePremium: onUpgrade,
        onSignIn: () {},
      ),
    ),
  );

  testWidgets('Upgrade on the Spicy Chest calls onUpgradePremium', (tester) async {
    var upgraded = 0;
    await tester.pumpWidget(host(premium: false, onUpgrade: () => upgraded++));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Upgrade →'));
    await tester.pump();
    expect(upgraded, 1);
  });

  testWidgets('Premium users see no Upgrade and no free chest', (tester) async {
    await tester.pumpWidget(host(premium: true, onUpgrade: () {}));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Upgrade →'), findsNothing);
    expect(find.text('Daily Chest'), findsNothing);
    expect(find.text('Spicy Chest'), findsOneWidget);
  });
}
