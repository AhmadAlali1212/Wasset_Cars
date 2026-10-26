import 'package:flutter/material.dart';

class AdChoiceSheet extends StatelessWidget {
  const AdChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'هل تريد إنشاء إعلان لهذه السيارة الآن؟',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: const Text('إعلان بيع'),
              onTap: () => Navigator.pop(context, 'sale'),
            ),
            ListTile(
              leading: const Icon(Icons.car_rental_outlined),
              title: const Text('إعلان تأجير'),
              onTap: () => Navigator.pop(context, 'rental'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('لاحقاً'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
