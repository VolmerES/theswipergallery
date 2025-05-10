import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/neon_container.dart';
import './select_album_screen.dart';
import 'select_month_screen.dart';
import '../theme/app_theme.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.darkBackground.withBlue(40),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gallery Cleaner',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¿Cómo quieres organizar tus fotos?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeonContainer(
                          borderColor: AppTheme.neonBlue,
                          child: CustomButton(
                            icon: Icons.folder_rounded,
                            label: 'Por carpetas',
                            description: 'Organiza las fotos según las carpetas del dispositivo',
                            onPressed: () => _navigate(context, GroupMode.folders),
                          ),
                        ),
                        const SizedBox(height: 24),
                        NeonContainer(
                          borderColor: AppTheme.neonPink,
                          child: CustomButton(
                            icon: Icons.calendar_month_rounded,
                            label: 'Por meses',
                            description: 'Organiza las fotos cronológicamente por meses',
                            onPressed: () => _navigate(context, GroupMode.months),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Desliza para guardar o eliminar imágenes',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}