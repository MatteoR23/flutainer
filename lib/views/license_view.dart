import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LicenseView extends StatelessWidget {
  const LicenseView({super.key});

  Future<String> _loadLicense() {
    return rootBundle.loadString('LICENSE.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licenza MIT'),
      ),
      body: FutureBuilder<String>(
        future: _loadLicense(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Impossibile caricare la licenza: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final text = snapshot.data ?? '';
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SelectionArea(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
