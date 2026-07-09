import 'package:flutter/material.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/section_header.dart';

import '../../widgets/auction/bid_history_item.dart';
import '../../widgets/auction/car_image_slider.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;

  const AuctionDetailScreen({super.key, required this.auction});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _bidController = TextEditingController();
  bool _isBidding = false;

  // Helper to parse formatted prices
  double _parsePrice(String price) {
    try {
      String cleanPrice = price.replaceAll(',', '').replaceAll(' ', '').replaceAll('ل.س', '');
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  // Helper to format prices for display
  String _formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
    String formatted = '';
    int counter = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      counter++;
      formatted = priceStr[i] + formatted;
      if (counter % 3 == 0 && i != 0) {
        formatted = ',$formatted';
      }
    }

    return '$formatted ل.س';
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = widget.auction.endTime.difference(DateTime.now());
    final hoursRemaining = timeRemaining.inHours;
    final daysRemaining = timeRemaining.inDays;

    // Parse current price once
    final currentPriceValue = _parsePrice(widget.auction.currentPrice);
    final startingPriceValue = _parsePrice(widget.auction.startingPrice);
    final minBid = currentPriceValue * 1.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المزاد'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Images
                CarImageSlider(images: widget.auction.car.images),

                // Auction Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Title
                      Text(
                        '${widget.auction.car.make} ${widget.auction.car.model} ${widget.auction.car.year}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Timer and Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.auction.status == 'active'
                                  ? AppColors.primary
                                  : widget.auction.status == 'ended'
                                  ? Colors.grey
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  widget.auction.status == 'active'
                                      ? '${daysRemaining}d ${hoursRemaining.remainder(24)}h'
                                      : widget.auction.status == 'ended'
                                      ? 'انتهى'
                                      : 'قريباً',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.auction.status == 'active'
                                  ? AppColors.success.withOpacity(0.2)
                                  : AppColors.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.auction.status == 'active'
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                            child: Text(
                              widget.auction.status == 'active' ? 'نشط' : 'منتهي',
                              style: TextStyle(
                                color: widget.auction.status == 'active'
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Price Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // العمود الأول - السعر الحالي
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'السعر الحالي',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatPrice(currentPriceValue),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16), // مسافة بين العمودين

                            // العمود الثاني - السعر الابتدائي
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'السعر الابتدائي',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatPrice(startingPriceValue),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Car Info
                      const SectionHeader(title: 'معلومات السيارة'),
                      const SizedBox(height: 12),
                      _buildCarInfoTable(),
                      const SizedBox(height: 20),

                      // Description
                      const SectionHeader(title: 'الوصف'),
                      const SizedBox(height: 12),
                      Text(
                        widget.auction.car.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bid History
                      if (widget.auction.bids.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'تاريخ المزايدات'),
                            const SizedBox(height: 12),
                            ...widget.auction.bids.reversed.map((bid) =>
                                BidHistoryItem(bid: bid)
                            ).toList(),
                          ],
                        ),

                      const SizedBox(height: 100), // Space for bid button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bid Button
          if (widget.auction.status == 'active')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isBidding)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _bidController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'أدخل المبلغ (الحد الأدنى: ${_formatPrice(minBid)})',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _isBidding = false),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: _submitBid,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (!_isBidding) {
                          setState(() => _isBidding = true);
                        } else {
                          _submitBid();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isBidding ? 'تأكيد المزايدة' : 'قدم مزايدة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarInfoTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            children: [
              Text('الماركة', style: TextStyle(color: AppColors.textSecondary)),
              Text(widget.auction.car.make, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]),
          TableRow(
            children: [
              Text('الموديل', style: TextStyle(color: AppColors.textSecondary)),
              Text(widget.auction.car.model, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]),
          TableRow(
            children: [
              Text('سنة الصنع', style: TextStyle(color: AppColors.textSecondary)),
              Text(widget.auction.car.year.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]),
          TableRow(
            children: [
              Text('الحالة', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                  widget.auction.car.condition == 'used' ? 'مستعمل' : 'جديد',
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]),
          TableRow(
            children: [
              Text('الموقع', style: TextStyle(color: AppColors.textSecondary)),
              Text(widget.auction.car.location, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]),
          TableRow(
            children: [
              Text('البائع', style: TextStyle(color: AppColors.textSecondary)),
              Text(widget.auction.car.userName,style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _submitBid() {
    // تنظيف النص المدخل: إزالة الفواصل والمسافات
    String bidAmountText = _bidController.text.replaceAll(',', '').replaceAll(' ', '').trim();

    // محاولة تحويل النص إلى double
    final bidAmount = double.tryParse(bidAmountText) ?? 0;

    // التحقق من أن القيمة المدخلة صالحة
    if (bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صالح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // حساب الحد الأدنى للمزايدة
    final minBid = _parsePrice(widget.auction.currentPrice) * 1.05;

    // التحقق من أن المبلغ المدخل أعلى من الحد الأدنى
    if (bidAmount < minBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المبلغ يجب أن يكون على الأقل ${_formatPrice(minBid)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // منطق تقديم المزايدة هنا
    setState(() {
      _isBidding = false;
      _bidController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تقديم مزايدتك بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }
}