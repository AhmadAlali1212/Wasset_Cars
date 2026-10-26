import 'package:flutter/material.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/widgets/sellCars/home_common_widgets.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/section_header.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/widgets/rental/rental_ads/rental_ad_cards.dart';

class RentalAdsViewAll extends StatelessWidget {
  final String title;
  final List<Ad> ads;
  final VoidCallback onBack;

  const RentalAdsViewAll({
    super.key,
    required this.title,
    required this.ads,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RentalAdCard(ad: ad, onTap: () => _openDetails(context, ad)),
          );
        },
      ),
    );
  }

  void _openDetails(BuildContext context, Ad ad) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RentalAdDetailScreen(ad: ad)),
    );
  }
}

class RentalAdsBody extends StatelessWidget {
  final List<Ad> rentalAds;
  final List<Ad> filteredAds;
  final List<Ad> featuredAds;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMorePages;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(String title, List<Ad> ads) onViewAll;
  final void Function(Ad ad) onAdTap;

  const RentalAdsBody({
    super.key,
    required this.rentalAds,
    required this.filteredAds,
    required this.featuredAds,
    required this.searchQuery,
    required this.isLoading,
    required this.errorMessage,
    required this.isLoadingMore,
    required this.hasMorePages,
    required this.scrollController,
    required this.onRefresh,
    required this.onViewAll,
    required this.onAdTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SkeletonCarGrid(itemCount: 6);

    if (errorMessage != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (searchQuery.isEmpty && featuredAds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: context.tr('featured_ads'),
                onViewAll:
                    () => onViewAll(
                      context.tr('featured_ads'),
                      rentalAds.where((ad) => ad.isFeatured).toList(),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: featuredAds.length,
                itemBuilder: (context, index) {
                  final ad = featuredAds[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: FeaturedRentalCard(ad: ad, onTap: () => onAdTap(ad)),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: context.tr('all_rental_ads'),
              onViewAll:
                  () => onViewAll(context.tr('all_rental_ads'), rentalAds),
            ),
          ),
          const SizedBox(height: 12),
          if (filteredAds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.tr('no_matching_results')),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredAds.length,
              itemBuilder: (context, index) {
                final ad = filteredAds[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RentalAdCard(ad: ad, onTap: () => onAdTap(ad)),
                );
              },
            ),
          if (searchQuery.isEmpty)
            LoadMoreFooter(
              isLoadingMore: isLoadingMore,
              hasMorePages: hasMorePages,
              showEndMessage: rentalAds.isNotEmpty,
            ),
        ],
      ),
    );
  }
}

class RentalAdsSortSheet extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onSelected;

  const RentalAdsSortSheet({
    super.key,
    required this.selectedMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('filter_ads'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SortOption(
            icon: Icons.sort,
            title: context.tr('newest'),
            mode: 'newest',
            selectedMode: selectedMode,
            onSelected: onSelected,
          ),
          _SortOption(
            icon: Icons.attach_money,
            title: context.tr('lowest_price'),
            mode: 'price_asc',
            selectedMode: selectedMode,
            onSelected: onSelected,
          ),
          _SortOption(
            icon: Icons.attach_money_outlined,
            title: context.tr('highest_price'),
            mode: 'price_desc',
            selectedMode: selectedMode,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String mode;
  final String selectedMode;
  final ValueChanged<String> onSelected;

  const _SortOption({
    required this.icon,
    required this.title,
    required this.mode,
    required this.selectedMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selectedMode == mode ? const Icon(Icons.check) : null,
      onTap: () => onSelected(mode),
    );
  }
}
