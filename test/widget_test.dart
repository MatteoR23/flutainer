// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';

import 'package:flutainer/main.dart';
import 'package:flutainer/services/credentials_storage.dart';
import 'package:flutainer/viewmodels/app_view_model.dart';

void main() {
  testWidgets('Home page shows empty state when there are no endpoints',
      (tester) async {
    final viewModel = AppViewModel(storage: MemoryCredentialsStorage());
    await tester.pumpWidget(FlutainerApp(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.text('Endpoints'), findsOneWidget);
    expect(
      find.textContaining('Non hai ancora configurato endpoint'),
      findsOneWidget,
    );
    expect(find.text('Aggiungi endpoint'), findsOneWidget);
  });
}
