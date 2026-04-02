import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            const SizedBox(height: 16),
            const Text('Oraiopoli', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 24),
            SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.7), strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}

