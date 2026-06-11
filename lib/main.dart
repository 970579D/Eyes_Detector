import 'package:flutter/material.dart';
import 'camera_page.dart';
import 'gallery_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Contact Capture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF2A2A2A),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──
              const SizedBox(height: 24),
              const Text(
                'Eye Contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Auto-captures when eye contact is detected',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 60),

              // ── Camera card ──
              _MenuCard(
                icon: Icons.camera_alt_outlined,
                title: 'Start Camera',
                subtitle: 'Detect eye contact and capture',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EyeContactCameraPage(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Gallery card ──
              _MenuCard(
                icon: Icons.photo_library_outlined,
                title: 'Gallery',
                subtitle: 'View captured photos',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryPage()),
                ),
              ),

              const Spacer(),

              // ── Footer ──
              const Center(
                child: Text(
                  'Photos are saved to your device gallery',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 18),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}