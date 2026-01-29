import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tourism_app/main.dart'; // Ensure this matches package name in pubspec.yaml. Assuming 'tourism_app' based on original test import. 

void main() {
  testWidgets('Welcome screen UI smoke test', (WidgetTester tester) async {
    // Build WelcomeScreen wrapped in MaterialApp to provide Theme, etc.
    // We avoid pumping MyApp() because it initializes services that require Firebase, which isn't mocked here.
    await tester.pumpWidget(const MaterialApp(
      home: WelcomeScreen(),
    ));

    // Verify that the welcome text is present.
    // Note: Text widgets with newlines might be split or handled specifically, 
    // but finding by 'Discover\nNew Adventures' string should work if it's exact.
    expect(find.textContaining('Discover'), findsOneWidget);
    expect(find.textContaining('New Adventures'), findsOneWidget);

    // Verify 'Get Started' button is present
    expect(find.text('Get Started'), findsOneWidget);

    // Verify the hidden admin access button (icon) is present
    expect(find.byIcon(Icons.mode_of_travel_sharp), findsOneWidget);
  });
}
