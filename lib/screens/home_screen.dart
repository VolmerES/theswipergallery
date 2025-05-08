import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import './select_album_screen.dart';
import 'select_month_screen.dart';

enum GroupMode { folders, months }

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _navigate(BuildContext context, GroupMode mode) {
    if (mode == GroupMode.folders) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SelectAlbumScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SelectMonthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo quieres agrupar las imágenes?')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                label: '📁 Por carpetas',
                onPressed: () => _navigate(context, GroupMode.folders),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: '🗓️ Por meses',
                onPressed: () => _navigate(context, GroupMode.months),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
