import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/app_view_model.dart';
import 'views/home_page_view.dart';

void main() {
  runApp(const FlutainerApp());
}

class FlutainerApp extends StatelessWidget {
  const FlutainerApp({super.key, AppViewModel? viewModel})
      : _viewModel = viewModel;

  final AppViewModel? _viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _viewModel ?? AppViewModel(),
      child: MaterialApp(
        title: 'Flutainer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const HomePageView(),
      ),
    );
  }
}
