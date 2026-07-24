import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/mock_data.dart' show MockData;
import 'package:mators_car/widgets/section_header.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Ad> _featuredAds = MockData.featuredAds;
  final List<Ad> _recommendedAds = MockData.recommendedAds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سوريا موتورز'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Ads Section
            FeaturedAdsSection(ads: _featuredAds),

            const SizedBox(height: 30),

            // Recommended Ads Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: 'إعلانات موصى بها',
                onViewAll: () {},
              ),
            ),
            const SizedBox(height: 16),
            _buildRecommendedAdsGrid(),

            const SizedBox(height: 30),

            // Recently Added Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: 'مضاف حديثاً',
                onViewAll: () {},
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentlyAddedList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecommendedAdsGrid() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: _recommendedAds.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AdCard(
              ad: _recommendedAds[index],
              onTap: () => _navigateToAdDetail(_recommendedAds[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentlyAddedList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recommendedAds.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AdListCard(
            ad: _recommendedAds[index],
            onTap: () => _navigateToAdDetail(_recommendedAds[index]),
          ),
        );
      },
    );
  }

  void _navigateToAdDetail(Ad ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdDetailScreen(ad: ad),
      ),
    );
  }
}