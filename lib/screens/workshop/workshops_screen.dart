import 'package:flutter/material.dart';
import 'package:mators_car/models/workshop_model.dart';
import 'package:mators_car/widgets/section_header.dart';
import 'package:mators_car/widgets/workshop/workshop_card.dart';
import '../../ulits/mock_data.dart';
import 'workshop_detail_screen.dart';

class WorkshopsScreen extends StatelessWidget {
  WorkshopsScreen({super.key});

  final List<Workshop> workshops = MockData.workshops;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الورشات المتاحة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ابحث داخل قائمة الورش من الشاشة الرئيسية'),
                ),
              );
            },
          ),
        ],
      ),
      body:
          workshops.isEmpty
              ? const Center(child: Text('لا توجد ورشات متاحة'))
              : CustomScrollView(
                slivers: [
                  // Featured Workshops Section
                  if (workshops.any((w) => w.featured))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 16,
                          top: 16,
                        ),
                        child: SectionHeader(
                          title: 'ورشات مميزة',
                          onViewAll: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'عرض الورشات المميزة متاح من القائمة الحالية',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (workshops.any((w) => w.featured))
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 240, // ارتفاع أكبر لاستيعاب البطاقة المعدلة
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          itemCount: workshops.where((w) => w.featured).length,
                          itemBuilder: (context, index) {
                            final featured =
                                workshops.where((w) => w.featured).toList();
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 320, // عرض أكبر لاستيعاب البطاقة المعدلة
                                child: WorkshopCard(
                                  workshop: featured[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => WorkshopDetailScreen(
                                              workshop: featured[index],
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // All Workshops Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SectionHeader(
                        title: 'جميع الورشات',
                        onViewAll: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جميع الورشات معروضة أدناه مباشرة'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: WorkshopCard(
                          workshop: workshops[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WorkshopDetailScreen(
                                      workshop: workshops[index],
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: workshops.length),
                  ),
                ],
              ),
    );
  }
}
