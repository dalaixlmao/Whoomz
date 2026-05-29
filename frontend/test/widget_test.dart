import 'package:flutter_test/flutter_test.dart';
import 'package:whoomz/main.dart';

void main() {
  testWidgets('app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoomzApp());
    expect(find.text('Whoomz'), findsOneWidget);
  });
}
