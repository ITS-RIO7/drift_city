import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drift_city/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('DRIFTCITY'), findsOneWidget);
  });
}
