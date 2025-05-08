import 'package:flutter/material.dart';
import '../widgets/loading_indicator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: const Center(
        child: LoadingIndicator(),
      ),
    );
  }
}
