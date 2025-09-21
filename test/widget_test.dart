import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiceRollerApp());

    // Verify that our counter starts at 0.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.text('Roll Dice'));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('1'), findsNothing);
    expect(find.text('6'), findsOneWidget);
  });
}
