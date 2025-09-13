import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutainer/main.dart';
import 'package:flutainer/screens/setup_screen.dart';

void main() {
  testWidgets('Flutainer mostra la setup screen se non ci sono credenziali', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutainerApp());
    await tester.pumpAndSettle();

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Portainer URL'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'API Key'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Connetti'), findsOneWidget);
  });
}
