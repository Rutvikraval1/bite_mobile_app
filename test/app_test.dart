import 'package:flutter_test/flutter_test.dart';

import 'package:bite/app.dart';

void main() {
  testWidgets('BiteApp boots to the config error when Supabase is missing',
      (tester) async {
    await tester.pumpWidget(const BiteApp());

    // Let the failed init future complete and the rebuild land.
    await tester.pump();
    await tester.pump();

    expect(find.text("Supabase isn't configured"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('config error retry re-runs init and shows the error again',
      (tester) async {
    await tester.pumpWidget(const BiteApp());
    await tester.pump();
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    // Init still fails (no env), so the error screen returns.
    await tester.pump();
    await tester.pump();
    expect(find.text("Supabase isn't configured"), findsOneWidget);
  });
}
