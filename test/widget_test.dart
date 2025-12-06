import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutainer/main.dart';
import 'package:flutainer/l10n/app_localizations_en.dart';
import 'package:flutainer/services/credentials_storage.dart';
import 'package:flutainer/viewmodels/app_view_model.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();

  setUp(() {
    binding.platformDispatcher.localesTestValue = const [Locale('en')];
    binding.platformDispatcher.localeTestValue = const Locale('en');
  });

  tearDown(() {
    binding.platformDispatcher.clearLocalesTestValue();
    binding.platformDispatcher.clearLocaleTestValue();
  });

  testWidgets('Home page shows empty state when there are no endpoints',
      (tester) async {
    final viewModel = AppViewModel(storage: MemoryCredentialsStorage());
    await tester.pumpWidget(FlutainerApp(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.endpointsTitle), findsOneWidget);
    expect(find.text(l10n.noEndpointsMessage), findsOneWidget);
    expect(find.text(l10n.addEndpoint), findsOneWidget);
  });
}
