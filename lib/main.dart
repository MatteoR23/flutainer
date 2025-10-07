import 'package:flutainer/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutainer/screens/setup_screen.dart';
import 'package:flutainer/screens/container_list_screen.dart';

void main() {
  runApp(const FlutainerApp());
}

class FlutainerApp extends StatelessWidget {
  const FlutainerApp({super.key});

  Future<Map<String, String?>> _loadCredentials() async {
    // const storage = FlutterSecureStorage();
    final store = SecureStorageService();
    final url = await store.read("url");
    final apiKey = await store.read("apiKey");
    return {'url': url, 'apiKey': apiKey};
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutainer',
      // Usa la modalità tema del sistema
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Map<String, String?>>(
        future: _loadCredentials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final creds = snapshot.data ?? {};
          if (creds['url'] == null || creds['apiKey'] == null) {
            return const SetupScreen();
          } else {
            return ContainerListScreen(url: creds['url']!, apiKey: creds['apiKey']!);
          }
        },
      ),
    );
  }
}
