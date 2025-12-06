import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutainer/viewmodels/locale_view_model.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    binding.platformDispatcher.localesTestValue = const [Locale('en')];
    binding.platformDispatcher.localeTestValue = const Locale('en');
  });

  tearDown(() {
    binding.platformDispatcher.clearLocalesTestValue();
    binding.platformDispatcher.clearLocaleTestValue();
  });

  test('uses system locale by default', () {
    final viewModel = LocaleViewModel();
    expect(viewModel.locale.languageCode, 'en');
    expect(viewModel.overrideLocale, isNull);
  });

  test('setLocale persists override and notifies listeners', () async {
    final viewModel = LocaleViewModel();
    var notifyCount = 0;
    viewModel.addListener(() => notifyCount++);

    final previousCount = notifyCount;
    await viewModel.setLocale(const Locale('it'));

    expect(viewModel.locale, const Locale('it'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_locale'), 'it');
    expect(notifyCount, greaterThanOrEqualTo(previousCount + 1));
  });

  test('clearing override restores system locale', () async {
    final viewModel = LocaleViewModel();
    final systemLocale = viewModel.locale;

    await viewModel.setLocale(const Locale('es'));
    expect(viewModel.locale, const Locale('es'));

    await viewModel.setLocale(null);
    expect(viewModel.locale, systemLocale);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('selected_locale'), isFalse);
  });

  test('unsupported locale is ignored', () async {
    final viewModel = LocaleViewModel();
    await viewModel.setLocale(const Locale('fr'));
    expect(viewModel.overrideLocale, isNull);
  });
}
