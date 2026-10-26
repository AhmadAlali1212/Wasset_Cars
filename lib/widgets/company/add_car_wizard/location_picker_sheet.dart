import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

class LocationPickerSheet extends StatelessWidget {
  final List<String> locations;
  final String selectedLocation;
  final VoidCallback onPickFromMap;
  final ValueChanged<String> onSelectLocation;
  final ValueChanged<String> onShowLocationOptions;
  final VoidCallback onAddLocation;

  const LocationPickerSheet({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onPickFromMap,
    required this.onSelectLocation,
    required this.onShowLocationOptions,
    required this.onAddLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'اختر موقع السيارة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onPickFromMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('تحديد الموقع على الخريطة'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (locations.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'أو اختر من المواقع المحفوظة',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...locations.map(
            (location) => Card(
              color:
                  location == selectedLocation
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surface,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(location),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => onShowLocationOptions(location),
                ),
                onTap: () => onSelectLocation(location),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddLocation,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('إضافة موقع نصي يدوياً'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
