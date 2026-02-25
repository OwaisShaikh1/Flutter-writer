// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:writer/main.dart';
import 'package:writer/database/database.dart';

void main() {
  testWidgets('Literature Dashboard smoke test', (WidgetTester tester) async {
    // Initialize database for testing
    final database = AppDatabase();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(database: database));

    // Wait for the app to load
    await tester.pump();

    // Verify that the Literature Dashboard loads.
    expect(find.text('Literature Dashboard'), findsOneWidget);
    
    // Clean up
    await database.close();
  });
}
