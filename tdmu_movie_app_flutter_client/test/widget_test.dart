// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:tdmu_movie_app_flutter_client/main.dart';

void main() {
  testWidgets('Shows auth screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(MovieApp(restoreSessionOnStart: false));
    await tester.pump();

    expect(find.text('TDMU Movie Auth'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
