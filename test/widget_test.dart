import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/main.dart';

void main() {
  testWidgets('Frame app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FrameApp()));
    await tester.pumpAndSettle();
    // App should render without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
