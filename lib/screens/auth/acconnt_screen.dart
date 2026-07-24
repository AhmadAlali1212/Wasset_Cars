import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/auth/acconnt_card.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                Text(
                  'اختر نوع الحساب',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر نوع الحساب الذي يناسب احتياجاتك',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      AccountTypeCard(
                        title: 'حساب فردي',
                        description:
                            'مناسب للأفراد الذين يرغبون ببيع أو شراء السيارات',
                        icon: Icons.person_outline,
                        accountTypeId: 1,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 20),
                      AccountTypeCard(
                        title: 'حساب شركة',
                        description: 'مخصص للشركات ووكلاء السيارات',
                        icon: Icons.business_outlined,
                        accountTypeId: 2,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
