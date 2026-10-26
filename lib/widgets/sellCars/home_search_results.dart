import 'package:flutter/material.dart';
import 'package:mators_car/data/models/car_model.dart';
import 'package:mators_car/widgets/sellCars/car_cards.dart';
import 'package:mators_car/widgets/sellCars/home_common_widgets.dart';

/// شبكة نتائج البحث بالشاشة الرئيسية — تُفلتر السيارات حسب الماركة/الموديل/
/// سنة الصنع بناءً على نص البحث. استُخرجت من _buildHomeSearchResults دون
/// أي تغيير بالمنطق أو التصميم.
class HomeSearchResultsGrid extends StatelessWidget {
  final List<Car> allCars;
  final String query;
  final bool Function(Car car) hasPromotion;
  final void Function(Car car) onCarTap;

  const HomeSearchResultsGrid({
    super.key,
    required this.allCars,
    required this.query,
    required this.hasPromotion,
    required this.onCarTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final results =
        allCars.where((car) {
          final haystack = '${car.make} ${car.model} ${car.year}'.toLowerCase();
          return haystack.contains(normalizedQuery);
        }).toList();

    if (results.isEmpty) {
      return EmptyHint('لا توجد نتائج مطابقة لـ "$query"');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final car = results[index];
        return GestureDetector(
          onTap: () => onCarTap(car),
          child: HomeCarCard(car: car, hasPromotion: hasPromotion(car)),
        );
      },
    );
  }
}
