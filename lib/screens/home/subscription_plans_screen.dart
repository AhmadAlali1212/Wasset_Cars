// screens/subscription/subscription_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  final Function(SubscriptionPlan) onPlanSelected;

  const SubscriptionPlansScreen({super.key, required this.onPlanSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر باقة الاشتراك'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SubscriptionPlanCard(
            plan: SubscriptionPlan(
              name: 'الباقة الأساسية',
              price: 10000,
              durationInDays: 30,
              features: [
                'نشر 3 إعلانات سيارات',
                'مزايدة على 5 سيارات',
                'إعلان واحد لتأجير السيارات',
              ],
            ),
            onSelected: onPlanSelected,
          ),
          const SizedBox(height: 16),
          SubscriptionPlanCard(
            plan: SubscriptionPlan(
              name: 'الباقة المميزة',
              price: 20000,
              durationInDays: 30,
              features: [
                'نشر 10 إعلانات سيارات',
                'مزايدة غير محدودة',
                '3 إعلانات لتأجير السيارات',
                'إظهار إعلاناتك في المقدمة',
              ],
              isRecommended: true,
            ),
            onSelected: onPlanSelected,
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlan {
  final String name;
  final double price;
  final int durationInDays;
  final List<String> features;
  final bool isRecommended;

  SubscriptionPlan({
    required this.name,
    required this.price,
    required this.durationInDays,
    required this.features,
    this.isRecommended = false,
  });
}

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final Function(SubscriptionPlan) onSelected;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: plan.isRecommended ? AppColors.primary : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'موصى بها',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              plan.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${plan.price.toStringAsFixed(0)} ل.س',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'لمدة ${plan.durationInDays} يوم',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(feature),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onSelected(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'اختيار الباقة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}