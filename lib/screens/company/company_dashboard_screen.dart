import 'package:flutter/material.dart';
import 'package:mators_car/screens/company/company_add_car_wizard_screen.dart';
import 'package:mators_car/screens/company/company_ads_screen.dart';
import 'package:mators_car/screens/company/company_inventory_screen.dart';
import 'package:mators_car/screens/company/company_profile_screen.dart';
import 'package:mators_car/screens/company/company_wallet_screen.dart';
import 'package:mators_car/screens/promotions/promotions_list_screen.dart';
import 'package:mators_car/screens/promotions/subscription_screen.dart';
import 'package:mators_car/screens/auction/my_auctions_screen.dart';
import 'package:mators_car/screens/auction/my_bids_screen.dart';
import 'package:mators_car/screens/adsCar/rental/my_rental_bookings_screen.dart';
import 'package:mators_car/screens/adsCar/rental/incoming_rental_bookings_screen.dart';
import 'package:mators_car/screens/messages/conversations_list_screen.dart';
import 'package:mators_car/screens/favorites/favorites_screen.dart';
import 'package:mators_car/screens/ratings/pending_ratings_screen.dart';
import 'package:mators_car/screens/disputes/my_disputes_screen.dart';
import 'package:mators_car/screens/settings/blocked_users_screen.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

class CompanyDashboardScreen extends StatelessWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('company_dashboard')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C81),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('welcome_company_dashboard'),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    context.tr('manage_cars_easily'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              context,
              title: context.tr('inventory'),
              subtitle: context.tr('inventory_subtitle'),
              icon: Icons.storefront_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CompanyInventoryScreen(
                          addCarScreenBuilder:
                              (_) => const CompanyAddCarWizardScreen(),
                        ),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('sales_rental_ads'),
              subtitle: context.tr('sales_rental_ads_subtitle'),
              icon: Icons.campaign_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompanyAdsScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('wallet'),
              subtitle: context.tr('wallet_subtitle'),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyWalletScreen(),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('subscription'),
              subtitle: context.tr('subscription_subtitle'),
              icon: Icons.workspace_premium_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('promotions'),
              subtitle: context.tr('promotions_subtitle'),
              icon: Icons.local_offer_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PromotionsScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('manage_auctions'),
              subtitle: context.tr('manage_auctions_subtitle'),
              icon: Icons.gavel_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAuctionsScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('my_bids'),
              subtitle: context.tr('my_bids_subtitle'),
              icon: Icons.emoji_events_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBidsScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('pending_ratings'),
              subtitle: context.tr('pending_ratings_subtitle'),
              icon: Icons.star_border,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PendingRatingsScreen(),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('my_disputes'),
              subtitle: context.tr('my_disputes_subtitle'),
              icon: Icons.gavel_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyDisputesScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('blocked_users'),
              subtitle: context.tr('manage_blocked_users'),
              icon: Icons.block,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('favorites'),
              subtitle: context.tr('favorites_subtitle'),
              icon: Icons.favorite_border,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('messages'),
              subtitle: context.tr('messages_subtitle'),
              icon: Icons.chat_bubble_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConversationsListScreen(),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('my_bookings'),
              subtitle: context.tr('my_bookings_subtitle'),
              icon: Icons.event_available_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyRentalBookingsScreen(),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('incoming_bookings'),
              subtitle: context.tr('incoming_bookings_subtitle'),
              icon: Icons.inbox_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncomingRentalBookingsScreen(),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('add_new_car'),
              subtitle: context.tr('add_new_car_subtitle'),
              icon: Icons.add_circle_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyAddCarWizardScreen(),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              title: context.tr('company_profile'),
              subtitle: context.tr('company_profile_subtitle'),
              icon: Icons.person_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C81).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF0F4C81), size: 26),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
