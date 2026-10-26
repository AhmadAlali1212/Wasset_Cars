import 'package:flutter/material.dart';
import 'package:mators_car/screens/individual/individual_add_car_screen.dart';
import 'package:mators_car/screens/individual/individual_ads_screen.dart';
import 'package:mators_car/screens/individual/individual_inventory_screen.dart';
import 'package:mators_car/screens/individual/individual_profile_screen.dart';
import 'package:mators_car/screens/individual/individual_wallet_screen.dart';
import 'package:mators_car/screens/auction/my_auctions_screen.dart';
import 'package:mators_car/screens/auction/my_bids_screen.dart';
import 'package:mators_car/screens/adsCar/rental/my_rental_bookings_screen.dart';
import 'package:mators_car/screens/adsCar/rental/incoming_rental_bookings_screen.dart';
import 'package:mators_car/screens/messages/conversations_list_screen.dart';
import 'package:mators_car/screens/favorites/favorites_screen.dart';
import 'package:mators_car/screens/ratings/pending_ratings_screen.dart';
import 'package:mators_car/screens/disputes/my_disputes_screen.dart';
import 'package:mators_car/screens/settings/blocked_users_screen.dart';
import 'package:mators_car/screens/company/following_companies_screen.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/ulits/constans.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/individual/dashboard_widgets.dart';

class IndividualDashboardScreen extends StatefulWidget {
  const IndividualDashboardScreen({super.key});

  @override
  State<IndividualDashboardScreen> createState() =>
      _IndividualDashboardScreenState();
}

class _IndividualDashboardScreenState extends State<IndividualDashboardScreen> {
  final CompanyService _carService = CompanyService();

  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<Map<String, dynamic>> _loadSummary() async {
    final myCars = await _carService.getMyCars();
    final allCars = await _carService.getAllCars();
    final wallet = await _carService.getWallet();
    return {'myCars': myCars, 'allCars': allCars, 'wallet': wallet};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('dashboard')),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: context.tr('profile'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IndividualProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${context.tr('account_data_load_failed')}\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final myCars = List<Map<String, dynamic>>.from(
            snapshot.data?['myCars'] ?? [],
          );
          final allCars = List<Map<String, dynamic>>.from(
            snapshot.data?['allCars'] ?? [],
          );
          final wallet = Map<String, dynamic>.from(
            snapshot.data?['wallet'] ?? {},
          );
          final walletData = wallet['wallet'];
          final balanceRaw =
              (walletData is Map ? walletData['available_balance'] : null) ??
              wallet['balance'] ??
              wallet['current_balance'] ??
              0;
          final balance = balanceRaw;
          final currency = wallet['currency'] ?? 'ل.س';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _summaryFuture = _loadSummary();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHeaderCard(balance: '$balance', currency: currency),
                  const SizedBox(height: 20),
                  DashboardActionTile(
                    title: context.tr('my_cars'),
                    subtitle: '${myCars.length} ${context.tr('cars_count')}',
                    icon: Icons.directions_car_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualInventoryScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('wallet'),
                    subtitle: context.tr('wallet_subtitle_individual'),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualWalletScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('my_ads'),
                    subtitle: context.tr('my_ads_subtitle'),
                    icon: Icons.campaign_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualAdsScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('my_auctions'),
                    subtitle: context.tr('my_auctions_subtitle'),
                    icon: Icons.gavel_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAuctionsScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
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
                  DashboardActionTile(
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
                  DashboardActionTile(
                    title: context.tr('my_disputes'),
                    subtitle: context.tr('my_disputes_subtitle'),
                    icon: Icons.gavel_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyDisputesScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('blocked_users'),
                    subtitle: context.tr('manage_blocked_users'),
                    icon: Icons.block,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BlockedUsersScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('favorites'),
                    subtitle: context.tr('favorites_subtitle'),
                    icon: Icons.favorite_border,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
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
                  DashboardActionTile(
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
                  DashboardActionTile(
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
                  DashboardActionTile(
                    title: context.tr('following_companies'),
                    subtitle: context.tr('following_companies_subtitle'),
                    icon: Icons.storefront_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FollowingCompaniesScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('add_new_car'),
                    subtitle: context.tr('car_review_subtitle'),
                    icon: Icons.add_circle_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualAddCarScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionTile(
                    title: context.tr('profile'),
                    subtitle: context.tr('edit_account_logout'),
                    icon: Icons.person_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.tr('all_available_cars'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (allCars.isEmpty)
                    const DashboardEmptyCarsHint()
                  else
                    Column(
                      children:
                          allCars.take(3).map((car) {
                            final imageUrl = AppConstants.resolveImageUrl(
                              car['images'] is List &&
                                      (car['images'] as List).isNotEmpty
                                  ? (car['images'] as List).first.toString()
                                  : null,
                            );

                            return DashboardAvailableCarTile(
                              car: car,
                              imageUrl: imageUrl,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            const IndividualInventoryScreen(),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
