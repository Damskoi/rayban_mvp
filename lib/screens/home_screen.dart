import 'package:flutter/material.dart';
import 'quick_vision_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      context,
                      title: "Live AI",
                      subtitle: "Real-time Chat",
                      icon: Icons.psychology_rounded,
                      gradientColors: [const Color(0xFF5A78FF), const Color(0xFF8B9FFF)],
                      isActive: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      context,
                      title: "Quick Vision",
                      subtitle: "Siri Voice Trigger",
                      icon: Icons.remove_red_eye_rounded,
                      gradientColors: [const Color(0xFFB523D5), const Color(0xFFD252F0)],
                      isActive: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QuickVisionScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      context,
                      title: "Live Translate",
                      subtitle: "18 Languages",
                      icon: Icons.language_rounded,
                      gradientColors: [const Color(0xFF0ACFB7), const Color(0xFF29E1CD)],
                      isActive: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      context,
                      title: "OpenClaw",
                      subtitle: "OpenClaw",
                      icon: Icons.link_rounded,
                      gradientColors: [const Color(0xFF9044FF), const Color(0xFFB580FF)],
                      isActive: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWideCard(
                context,
                title: "RTMP Streaming",
                subtitle: "YouTube · Twitch\n· Bilibili",
                badge: "Experi-\nmental",
                icon: Icons.sensors_rounded,
                gradientColors: [const Color(0xFFFF4949), const Color(0xFFFF8B26)],
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge.replaceAll('\n', ''),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.replaceAll('\n', ' '),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
