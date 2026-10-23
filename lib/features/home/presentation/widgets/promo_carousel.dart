import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/ui_kit.dart';

class _PromoSlide {
  const _PromoSlide({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.ctaLabel,
  });

  final String eyebrow;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final String ctaLabel;
}

const List<_PromoSlide> _slides = [
  _PromoSlide(
    eyebrow: 'URGENT HIRING',
    icon: Icons.bolt_rounded,
    title: 'Fill roles 2× faster with an Urgent badge',
    subtitle: 'Urgent jobs show first to active job seekers',
    route: RoutePaths.postJob,
    ctaLabel: 'Post a Job',
  ),
  _PromoSlide(
    eyebrow: 'FREELANCE TALENT',
    icon: Icons.laptop_mac_rounded,
    title: 'Hire verified freelancers for any project',
    subtitle: 'Pay safely with milestone escrow',
    route: RoutePaths.postProject,
    ctaLabel: 'Post a Project',
  ),
  _PromoSlide(
    eyebrow: 'TALENT SEARCH',
    icon: Icons.person_search_rounded,
    title: 'Reach 2 lakh+ job seekers directly',
    subtitle: 'Search profiles and invite them to apply',
    route: RoutePaths.talentSearch,
    ctaLabel: 'Find Talent',
  ),
  _PromoSlide(
    eyebrow: 'GROWTH PLAN',
    icon: Icons.workspace_premium_rounded,
    title: 'Get 15 job posts and AI match scores',
    subtitle: 'Upgrade your plan and hire smarter',
    route: RoutePaths.plans,
    ctaLabel: 'View Plans',
  ),
];

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _slides.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _open(_PromoSlide slide) => context.push(slide.route);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3EA8), Color(0xFF1863DA), Color(0xFF4A95F2)],
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => _SlideBody(
              slide: _slides[index],
              onTap: () => _open(_slides[index]),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 4.5,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _page == i ? 1 : 0.45,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideBody extends StatelessWidget {
  const _SlideBody({required this.slide, required this.onTap});

  final _PromoSlide slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative art on the right.
        Positioned(
          right: -20,
          bottom: -24,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 22,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Icon(slide.icon, color: Colors.white, size: 30),
          ),
        ),
        Positioned(
          right: 9,
          top: 12,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 120, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                slide.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slide.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 9.5,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              WhitePillButton(
                label: slide.ctaLabel,
                height: 23,
                fontSize: 9,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
