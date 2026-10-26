import 'package:flutter/material.dart';

/// ودجات العروض الترويجية بالشاشة الرئيسية — استُخرجت من دوال _build...
/// الخاصة بالـ State دون أي تغيير بالتصميم أو المنطق.

/// بطاقة عرض ترويجي واحدة (بلون تدرج أزرق)، تُستخدم إما بعرض ثابت (220)
/// داخل صف أفقي، أو بعرض كامل (fullWidth) عند وجود عرض واحد فقط.
class PromotionCard extends StatelessWidget {
  final Map<String, dynamic> promo;
  final bool fullWidth;

  const PromotionCard({super.key, required this.promo, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final title = (promo['title'] ?? 'عرض ترويجي').toString();
    final description = (promo['description'] ?? '').toString();
    final type = (promo['type'] ?? '').toString();
    final value = promo['value']?.toString() ?? '';
    final endDate = (promo['end_date'] ?? '').toString();

    final valueLabel =
        value.isEmpty
            ? ''
            : type == 'discount'
            ? 'خصم $value%'
            : value;

    return Container(
      width: fullWidth ? double.infinity : 220,
      margin: EdgeInsets.only(left: fullWidth ? 0 : 12, bottom: fullWidth ? 12 : 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (valueLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    valueLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F4C81),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (endDate.isNotEmpty)
                Text(
                  'حتى $endDate',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// صف أفقي قابل للتمرير من بطاقات العروض الترويجية.
class PromotionsRow extends StatelessWidget {
  final List<Map<String, dynamic>> promotions;

  const PromotionsRow({super.key, required this.promotions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        itemBuilder: (context, index) => PromotionCard(promo: promotions[index]),
      ),
    );
  }
}
