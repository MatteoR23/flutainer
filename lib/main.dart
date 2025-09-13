import 'package:flutter/material.dart';
import 'package:flutainer/screens/setup_screen.dart';
import 'package:flutainer/screens/container_list_screen.dart';
import 'package:secure_store/secure_store.dart';

void main() {
  PasswordStore.init();
  runApp(const FlutainerApp());
}

class FlutainerApp extends StatelessWidget {
  const FlutainerApp({super.key});

  Future<Map<String, String?>> _loadCredentials() async {
    // const storage = FlutterSecureStorage();
    final url = await PasswordStore(password: '1234').getSecret(
      key: "password-store:url",
    );
    final apiKey = await PasswordStore(password: '1234').getSecret(
      key: "password-store:apiKey",
    );
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
