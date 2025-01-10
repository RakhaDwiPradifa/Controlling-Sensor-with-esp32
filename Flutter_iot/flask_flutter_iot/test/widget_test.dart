// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iot/main.dart';


void main() {
testWidgets('Home page navigation test', (WidgetTester tester) async {
  await tester.pumpWidget(const SensorApp());
  expect(find.text('Home'), findsOneWidget);

  await tester.tap(find.text('Sensor MQ135 Value'));
  await tester.pumpAndSettle();

  expect(find.text('Charts'), findsOneWidget);
});

}
