import 'package:flutter/material.dart';
import 'package:secure_store/secure_store.dart';
import 'container_list_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  //final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurazione Flutainer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: "Portainer URL"),
                validator: (value) => value == null || value.isEmpty ? "Inserisci l'URL" : null,
              ),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(labelText: "API Key"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Inserisci la API Key" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await PasswordStore(password: '1234').storeSecret(
                      secret: _urlController.text,
                      key: "password-store:url",
                    );
                    await PasswordStore(password: '1234').storeSecret(
                      secret: _apiKeyController.text,
                      key: "password-store:apiKey",
                    );
                    //await storage.write(key: 'url', value: _urlController.text);
                    //await storage.write(key: 'apiKey', value: _apiKeyController.text);
                    if (!mounted) return;
                    await Future.delayed(const Duration(seconds: 1));
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ContainerListScreen(
                                  url: _urlController.text,
                                  apiKey: _apiKeyController.text,
                                )),
                      );
                    }
                  }
                },
                child: const Text("Connetti"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
