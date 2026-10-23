import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    final minSplashDelay = Future.delayed(const Duration(milliseconds: 2300));
    final authReady = ref.read(authProvider.notifier).ready;
    await Future.wait([minSplashDelay, authReady]);
    if (!mounted) return;

    final authState = ref.read(authProvider);
    context.go(
      authState.status == AuthStatus.authenticated
          ? RoutePaths.home
          : RoutePaths.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft light-blue background with a big blob top-left.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF2F7FE), Colors.white, Color(0xFFF4F8FE)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -70,
            top: -60,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDDEBFC),
              ),
            ),
          ),
          Positioned(
            right: -24,
            top: size.height * 0.16,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAF2FD),
              ),
            ),
          ),
          // Paper plane with a dashed trail.
          Positioned(
            right: 18,
            top: size.height * 0.085,
            child: SizedBox(
              width: 80,
              height: 60,
              child: CustomPaint(painter: _TrailPainter()),
            ),
          ),
          Positioned(
            right: 16,
            top: size.height * 0.085,
            child: Transform.rotate(
              angle: -0.45,
              child: const Icon(
                Icons.send_rounded,
                size: 30,
                color: Color(0xFF2E7BEA),
              ),
            ),
          ),
          // Bottom waves, skyline, plant and slogan.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.31,
            child: const _WaveFooter(),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.115),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      AppStrings.logo,
                      width: 240,
                      semanticLabel: AppStrings.appName,
                    ),
                    const Positioned(
                      left: 18,
                      top: 82,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Color(0xFF3B8BEA),
                      ),
                    ),
                    const Positioned(
                      right: 30,
                      top: 70,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 11,
                        color: AppColors.brandAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'FOR RECRUITERS & CLIENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Post Jobs. Hire Freelancers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1B3D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Build Your Team — All in One Platform.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF4A5468)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 84,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [AppColors.tintBlue, AppColors.tintGreen],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Feature(
                        icon: Icons.post_add_rounded,
                        color: AppColors.tintBlue,
                        title: 'Post Jobs',
                        subtitle: 'Reach thousands of job seekers',
                      ),
                      _Feature(
                        icon: Icons.laptop_rounded,
                        color: AppColors.tintOrange,
                        title: 'Freelance',
                        subtitle: 'Hire experts for projects',
                      ),
                      _Feature(
                        icon: Icons.person_search_rounded,
                        color: AppColors.tintGreen,
                        title: 'Find Talent',
                        subtitle: 'Search verified profiles',
                      ),
                      _Feature(
                        icon: Icons.insert_chart_rounded,
                        color: AppColors.tintPurple,
                        title: 'Track',
                        subtitle: 'Manage hiring end to end',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => Container(
                    width: 195,
                    height: 8,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3ECF8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.08 + 0.92 * _progress.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1560D8), Color(0xFF2E8BF0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Setting up your hiring workspace...',
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF4A5468),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: i == 0 ? 7 : 5.5,
                        height: i == 0 ? 7 : 5.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? const Color(0xFF1046A8)
                              : const Color(0xFFB4CAE8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F1B3D),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 8.5,
                height: 1.3,
                color: Color(0xFF5B6475),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blue/green waves with a faint skyline, a sprouting plant and the slogan.
class _WaveFooter extends StatelessWidget {
  const _WaveFooter();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _WavePainter()),
        const Positioned(
          right: 40,
          bottom: 66,
          child: Icon(Icons.spa_rounded, size: 60, color: Color(0xFF46B04A)),
        ),
        const Positioned(left: 22, bottom: 50, child: _Slogan()),
      ],
    );
  }
}

class _Slogan extends StatelessWidget {
  const _Slogan();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    return Transform.rotate(
      angle: -0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Great Teams', style: base),
          const Text('Build Great Companies', style: base),
          Text(
            'Hire Smarter',
            style: base.copyWith(color: const Color(0xFF6FE3F5), fontSize: 16),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2, left: 20),
            width: 100,
            height: 2,
            color: const Color(0xFF6FE3F5),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Faint city skyline.
    final city = Paint()..color = const Color(0xFFD6E6F8);
    final blocks = [
      (0.42, 0.42, 0.05),
      (0.48, 0.36, 0.04),
      (0.53, 0.46, 0.05),
      (0.78, 0.18, 0.05),
      (0.84, 0.30, 0.04),
      (0.89, 0.10, 0.05),
      (0.95, 0.24, 0.05),
    ];
    for (final b in blocks) {
      canvas.drawRect(
        Rect.fromLTWH(w * b.$1, h * b.$2, w * b.$3, h * 0.6),
        city,
      );
    }

    // Light sky-blue back wave.
    final back = Path()
      ..moveTo(0, h * 0.18)
      ..cubicTo(w * 0.3, h * 0.30, w * 0.55, h * 0.58, w, h * 0.50)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8FC5F5), Color(0xFFBFE0FB)],
        ).createShader(Offset.zero & size),
    );

    // Main blue wave.
    final main = Path()
      ..moveTo(0, h * 0.40)
      ..cubicTo(w * 0.25, h * 0.48, w * 0.6, h * 0.82, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      main,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E7BE0), Color(0xFF0A3C9E)],
        ).createShader(Offset.zero & size),
    );

    // Green hill on the right.
    final green = Path()
      ..moveTo(w * 0.45, h)
      ..cubicTo(w * 0.7, h * 0.78, w * 0.85, h * 0.62, w, h * 0.66)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      green,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2FAE6A), Color(0xFF8BD45A)],
        ).createShader(Offset.zero & size),
    );

    // Deep navy front wave on the left.
    final front = Path()
      ..moveTo(0, h * 0.62)
      ..cubicTo(w * 0.3, h * 0.72, w * 0.5, h * 0.98, w * 0.7, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF0B2F7A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7FB2F0)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.75, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.6,
        size.width * 0.12,
        size.height * 0.75,
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.9), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
