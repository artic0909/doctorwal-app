import 'package:flutter/material.dart';

/// Shimmer widget that animates a radiant gradient over child placeholder shapes.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE8EEF5),
    this.highlightColor = const Color(0xFFF6F9FC),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
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
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.1, 0.5, 0.9],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
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
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// A versatile skeleton shape element
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final Color color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.color = const Color(0xFFE2E8F0),
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
    this.margin,
    this.color = const Color(0xFFE2E8F0),
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for Appointments Screen
class AppointmentsSkeleton extends StatelessWidget {
  final int itemCount;
  const AppointmentsSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Column(
            children: [
              // Top Header (Date/Time bar)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SkeletonBox(width: 90, height: 14, borderRadius: 4),
                      Spacer(),
                      SkeletonBox(width: 70, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
              ),
              // Body Details
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 60, height: 60, borderRadius: 16),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 150, height: 16, borderRadius: 4),
                          SizedBox(height: 8),
                          SkeletonBox(width: 100, height: 12, borderRadius: 4),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              SkeletonBox(width: 70, height: 20, borderRadius: 10),
                              SizedBox(width: 8),
                              SkeletonBox(width: 60, height: 20, borderRadius: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Footer Action
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SkeletonBox(width: 100, height: 34, borderRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Medical History (Prescriptions & Test Reports) Screen
class MedicalHistorySkeleton extends StatelessWidget {
  final int itemCount;
  const MedicalHistorySkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 48, height: 48, borderRadius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 15, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 110, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 80, height: 11, borderRadius: 4),
                  ],
                ),
              ),
              SkeletonBox(width: 36, height: 36, borderRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Health Parameters / Vitals Screen
class HealthParametersSkeleton extends StatelessWidget {
  final int itemCount;
  const HealthParametersSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 38, height: 38, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 130, height: 15, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 60, height: 22, borderRadius: 12),
                ],
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Doctors Screen
class DoctorsListSkeleton extends StatelessWidget {
  final int itemCount;
  const DoctorsListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 72, height: 72, borderRadius: 16),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 130, height: 11, borderRadius: 4),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        SkeletonBox(width: 70, height: 24, borderRadius: 8),
                        Spacer(),
                        SkeletonBox(width: 80, height: 28, borderRadius: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for OPD Clinics Screen
class OpdListSkeleton extends StatelessWidget {
  final int itemCount;
  const OpdListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 50, height: 50, borderRadius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 170, height: 15, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(width: 120, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 80, height: 24, borderRadius: 8),
                  SkeletonBox(width: 90, height: 30, borderRadius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Pathology Centers Screen
class PathologyListSkeleton extends StatelessWidget {
  final int itemCount;
  const PathologyListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 50, height: 50, borderRadius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 15, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(width: 110, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 60, height: 24, borderRadius: 8),
                ],
              ),
              SizedBox(height: 12),
              SkeletonBox(width: 200, height: 12, borderRadius: 4),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 90, height: 26, borderRadius: 8),
                  SkeletonBox(width: 90, height: 30, borderRadius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single Doctor Card Skeleton for infinite scroll loading indicator
class DoctorCardSkeleton extends StatelessWidget {
  const DoctorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6A1B9A).withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withAlpha(8),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 80, height: 80, borderRadius: 15),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 12, borderRadius: 4),
                  SizedBox(height: 10),
                  SkeletonBox(width: double.infinity, height: 11, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single OPD Clinic Card Skeleton for infinite scroll loading indicator
class OpdCardSkeleton extends StatelessWidget {
  const OpdCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1565C0).withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withAlpha(8),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 80, height: 80, borderRadius: 15),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 170, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 12, borderRadius: 4),
                  SizedBox(height: 10),
                  SkeletonBox(width: double.infinity, height: 11, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single Pathology Lab Card Skeleton for infinite scroll loading indicator
class PathologyCardSkeleton extends StatelessWidget {
  const PathologyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E7D32).withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withAlpha(8),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 80, height: 80, borderRadius: 15),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 170, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 12, borderRadius: 4),
                  SizedBox(height: 10),
                  SkeletonBox(width: double.infinity, height: 11, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Search Results
class SearchResultsSkeleton extends StatelessWidget {
  final int itemCount;
  const SearchResultsSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 65, height: 65, borderRadius: 16),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 11, borderRadius: 4),
                    SizedBox(height: 12),
                    SkeletonBox(width: 90, height: 28, borderRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Notification List
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;
  const NotificationListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox.circle(size: 40),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 15, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Blogs Screen
class BlogListSkeleton extends StatelessWidget {
  final int itemCount;
  const BlogListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                width: double.infinity,
                height: 150,
                borderRadius: 18,
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 80, height: 18, borderRadius: 6),
                    SizedBox(height: 10),
                    SkeletonBox(width: double.infinity, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Coupons Screen
class CouponListSkeleton extends StatelessWidget {
  final int itemCount;
  const CouponListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 44, height: 44, borderRadius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 190, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              SkeletonBox(width: 70, height: 32, borderRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
