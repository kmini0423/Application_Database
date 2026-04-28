// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cs348_project/main.dart';

void main() {
  testWidgets('Hello World screen shows app name', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CarMeetApp());

    // Verify that the Hello World screen is shown
    expect(find.text('Hello World!'), findsOneWidget);
    expect(find.text('Car Meet Management App'), findsOneWidget);
  });
}
