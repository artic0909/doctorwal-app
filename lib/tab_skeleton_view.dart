import 'package:flutter/material.dart';

/// ShimmerLoading provides a sweeping gradient shimmer effect over placeholder widgets.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..repeat(
        min: -0.5,
        max: 1.5,
        period: const Duration(milliseconds: 1100),
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.1, 0.45, 0.85],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// TabSkeletonView renders a skeleton screen structure matching each bottom nav tab.
class TabSkeletonView extends StatelessWidget {
  final int tabIndex;

  const TabSkeletonView({super.key, required this.tabIndex});

  Widget _box({
    required double width,
    required double height,
    double borderRadius = 8,
    Color color = const Color(0xFFE2E8F0),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topSafe = statusBarHeight > 0 ? statusBarHeight : 24.0;

    Widget skeleton;
    switch (tabIndex) {
      case 0:
        skeleton = _buildHomeSkeleton(topSafe);
        break;
      case 1:
        skeleton = _buildSearchSkeleton(topSafe);
        break;
      case 2:
        skeleton = _buildMyHealthSkeleton(topSafe);
        break;
      case 3:
      default:
        skeleton = _buildAccountSkeleton(topSafe);
        break;
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: ShimmerLoading(child: skeleton),
    );
  }

  // --- TAB 0: HOME SKELETON ---
  Widget _buildHomeSkeleton(double topSafe) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top App Bar (Location + Profile Avatar)
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, topSafe + 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _box(width: 14, height: 14, borderRadius: 4, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 6),
                    _box(width: 90, height: 15, borderRadius: 4),
                  ],
                ),
                _box(width: 38, height: 38, borderRadius: 19),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Search Bar placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _box(width: double.infinity, height: 48, borderRadius: 14),
          ),
          const SizedBox(height: 18),

          // 3. Categories Circular Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Column(
                  children: [
                    _box(width: 54, height: 54, borderRadius: 27),
                    const SizedBox(height: 8),
                    _box(width: 44, height: 10, borderRadius: 4),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Large Promo/Banner Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _box(width: double.infinity, height: 145, borderRadius: 18),
          ),
          const SizedBox(height: 22),

          // 5. Section Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _box(width: 130, height: 16, borderRadius: 4),
                _box(width: 50, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 6. 2x2 Grid of Doctor / Specialty cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _box(width: double.infinity, height: 110, borderRadius: 14)),
                const SizedBox(width: 12),
                Expanded(child: _box(width: double.infinity, height: 110, borderRadius: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: SEARCH SKELETON ---
  Widget _buildSearchSkeleton(double topSafe) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topSafe + 8),
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _box(width: double.infinity, height: 48, borderRadius: 14),
          ),
          const SizedBox(height: 14),

          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _box(width: 85, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
                _box(width: 100, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
                _box(width: 90, height: 32, borderRadius: 16),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search Result Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        _box(width: 44, height: 44, borderRadius: 12),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _box(width: 160, height: 14, borderRadius: 4),
                              const SizedBox(height: 6),
                              _box(width: 100, height: 11, borderRadius: 4),
                              const SizedBox(height: 6),
                              _box(width: 70, height: 10, borderRadius: 4),
                            ],
                          ),
                        ),
                        _box(width: 65, height: 28, borderRadius: 8),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: MY HEALTH SKELETON ---
  Widget _buildMyHealthSkeleton(double topSafe) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Header Block
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, topSafe + 12, 18, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(width: 44, height: 44, borderRadius: 22, color: Colors.white24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 110, height: 15, borderRadius: 4, color: Colors.white30),
                        const SizedBox(height: 5),
                        _box(width: 80, height: 11, borderRadius: 4, color: Colors.white24),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Medical Card Plate
                _box(width: double.infinity, height: 60, borderRadius: 16, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4 Action Tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        _box(width: 38, height: 38, borderRadius: 10),
                        const SizedBox(width: 12),
                        Expanded(child: _box(width: 150, height: 14, borderRadius: 4)),
                        _box(width: 14, height: 14, borderRadius: 3),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _box(width: 130, height: 16, borderRadius: 4),
          ),
          const SizedBox(height: 10),

          // Horizontal Cards Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _box(width: double.infinity, height: 160, borderRadius: 18)),
                const SizedBox(width: 12),
                _box(width: 60, height: 160, borderRadius: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: ACCOUNT SKELETON ---
  Widget _buildAccountSkeleton(double topSafe) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Header Block
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, topSafe + 12, 18, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Row
                Row(
                  children: [
                    _box(width: 46, height: 46, borderRadius: 23, color: Colors.white24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 120, height: 16, borderRadius: 4, color: Colors.white30),
                        const SizedBox(height: 5),
                        _box(width: 140, height: 11, borderRadius: 4, color: Colors.white24),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Redesigned Eye-Catchy Medical Card Placeholder
                Container(
                  width: double.infinity,
                  height: 195,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _box(width: 110, height: 16, borderRadius: 4, color: Colors.white24),
                          _box(width: 40, height: 28, borderRadius: 6, color: Colors.white30),
                        ],
                      ),
                      _box(width: 200, height: 22, borderRadius: 4, color: Colors.white30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _box(width: 90, height: 14, borderRadius: 4, color: Colors.white24),
                          _box(width: 80, height: 14, borderRadius: 4, color: Colors.white24),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Update Profile Card Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _box(width: 38, height: 38, borderRadius: 10),
                      const SizedBox(width: 12),
                      Expanded(child: _box(width: 110, height: 14, borderRadius: 4)),
                      _box(width: 40, height: 18, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _box(width: double.infinity, height: 4, borderRadius: 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),

          // Action Tiles Placeholders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        _box(width: 38, height: 38, borderRadius: 10),
                        const SizedBox(width: 12),
                        Expanded(child: _box(width: 130, height: 14, borderRadius: 4)),
                        _box(width: 13, height: 13, borderRadius: 3),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
