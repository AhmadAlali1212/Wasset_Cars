import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/services/controllers/follow_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'company_public_profile_screen.dart';

class FollowingCompaniesScreen extends StatefulWidget {
  const FollowingCompaniesScreen({super.key});

  @override
  State<FollowingCompaniesScreen> createState() =>
      _FollowingCompaniesScreenState();
}

class _FollowingCompaniesScreenState extends State<FollowingCompaniesScreen> {
  final FollowService _followService = FollowService();
  late Future<List<Map<String, dynamic>>> _companiesFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _companiesFuture = _followService.getMyFollowingCompanies();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _companiesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(context.tr('following_companies')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: context.tr('search_company'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.adaptiveCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _companiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            '${context.tr('following_companies_load_failed')}\n'
                            '${ApiException.userMessage(snapshot.error)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  var companies = snapshot.data ?? [];
                  if (_query.isNotEmpty) {
                    companies =
                        companies
                            .where(
                              (c) => (c['name'] ?? c['company_name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(_query.toLowerCase()),
                            )
                            .toList();
                  }

                  if (companies.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 100),
                        Icon(
                          Icons.storefront_outlined,
                          size: 56,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(context.tr('no_followed_companies')),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: companies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _CompanyFollowCard(company: companies[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyFollowCard extends StatelessWidget {
  final Map<String, dynamic> company;

  const _CompanyFollowCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final name =
        (company['name'] ?? company['company_name'] ?? 'شركة').toString();
    final location = (company['city'] ?? company['location'] ?? '').toString();
    final followers = company['followers_count'];
    final logoUrl = AppConstants.resolveImageUrl(
      company['logo'] ?? company['profile_image'] ?? company['avatar'],
    );
    final verified =
        company['verified'] == true || company['is_verified'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                logoUrl != null
                    ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      memCacheWidth: 112,
                      placeholder:
                          (_, __) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFFF0F0F0),
                          ),
                      errorWidget:
                          (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.storefront),
                          ),
                    )
                    : Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.storefront),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('car_dealership'),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (followers != null) ...[
                      const Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$followers ${context.tr('followers')}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyPublicProfileScreen(company: company),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(context.tr('view_profile')),
          ),
        ],
      ),
    );
  }
}
