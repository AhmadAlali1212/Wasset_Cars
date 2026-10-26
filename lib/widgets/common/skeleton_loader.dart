import 'package:flutter/material.dart';

/// عنصر واحد متحرك (نبض تدريجي بالشفافية) يُستخدم كبديل عن
/// CircularProgressIndicator الفارغ بمعظم الشاشات — يعطي إحساساً بالسرعة
/// لأنه يعرض هيكل الشاشة الحقيقي فوراً بدل دائرة تحميل لا تدل على شيء.
/// لا يعتمد على أي حزمة خارجية جديدة (بدون shimmer package).
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.85,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: _opacity.value * 0.3),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// هيكل بطاقة سيارة (للشبكات: الشاشة الرئيسية، نتائج البحث، إلخ)
class SkeletonCarCard extends StatelessWidget {
  const SkeletonCarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const SkeletonBox(height: double.infinity, width: double.infinity),
            ),
          ),
          const SizedBox(height: 8),
          const SkeletonBox(height: 12, width: 100),
          const SizedBox(height: 6),
          const SkeletonBox(height: 12, width: 70),
        ],
      ),
    );
  }
}

/// شبكة من بطاقات هيكلية بنفس أبعاد شبكة السيارات الحقيقية
class SkeletonCarGrid extends StatelessWidget {
  final int itemCount;
  const SkeletonCarGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCarCard(),
    );
  }
}

/// هيكل صف قائمة (إشعار، حجز، رسالة، إلخ): صورة/أيقونة دائرية + سطرين نص
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SkeletonBox(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 13, width: 160),
                SizedBox(height: 8),
                SkeletonBox(height: 11, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة من صفوف هيكلية — بديل مباشر لأي `Center(child: CircularProgressIndicator())`
/// بشاشات القوائم (إشعارات، حجوزات، محادثات، إلخ)
class SkeletonList extends StatelessWidget {
  final int itemCount;
  const SkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }
}
