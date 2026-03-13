import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/animated_typewriter_text.dart';
import '../../../../l10n/l10n_extension.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_PresentationSlide> _getSlides(BuildContext context) {
    return [
      _PresentationSlide(
        title: context.l10n.presentationSlide1Title,
        body: context.l10n.presentationSlide1Body,
        icon: Icons.shield_rounded,
      ),
      _PresentationSlide(
        title: context.l10n.presentationSlide2Title,
        body: context.l10n.presentationSlide2Body,
        icon: Icons.account_balance_wallet_rounded,
      ),
      _PresentationSlide(
        title: context.l10n.presentationSlide3Title,
        body: context.l10n.presentationSlide3Body,
        icon: Icons.percent_rounded,
      ),
      _PresentationSlide(
        title: context.l10n.presentationSlide4Title,
        body: context.l10n.presentationSlide4Body,
        icon: Icons.insights_rounded,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int totalSlides) {
    if (_currentPage < totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishPresentation() {
    // When finished, go to Signup screen
    Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A), // Deep graphite / blue
      body: Stack(
        children: [
          // Premium Background Glows
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E2B4D).withValues(alpha: 0.3),
                    const Color(0xFF1E2B4D).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0C162C).withValues(alpha: 0.4),
                    const Color(0xFF0C162C).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finishPresentation,
                    child: Text(
                      context.l10n.presentationSkip,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(slides[index], index == _currentPage);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: _currentPage == index ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Next / Get Started Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage == slides.length - 1) {
                            _finishPresentation();
                          } else {
                            _nextPage(slides.length);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _currentPage == slides.length - 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: _currentPage == slides.length - 1
                                  ? Colors.transparent
                                  : Colors.white24,
                            ),
                            boxShadow: _currentPage == slides.length - 1
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == slides.length - 1
                                    ? context.l10n.presentationStart
                                    : context.l10n.presentationNext,
                                style: GoogleFonts.inter(
                                  color: _currentPage == slides.length - 1
                                      ? const Color(0xFF0A0F1A)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (_currentPage < slides.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_PresentationSlide slide, bool isActive) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: isActive ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        offset: isActive ? Offset.zero : const Offset(0, 0.05),
        curve: Curves.easeOutCubic,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Icon(slide.icon, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      slide.title,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedTypewriterText(
                      text: slide.body,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(
                      height: 48,
                    ), // Add some bottom padding for scroll
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PresentationSlide {
  final String title;
  final String body;
  final IconData icon;

  _PresentationSlide({
    required this.title,
    required this.body,
    required this.icon,
  });
}
