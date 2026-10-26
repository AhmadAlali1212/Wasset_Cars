import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mators_car/ulits/map_utils.dart';
import 'package:mators_car/data/models/ad_model.dart';

// كانت هذه الشاشة تستخدم flutter_map مع بلاطات OpenStreetMap
// (tile.openstreetmap.org)، وكانت هذه البلاطات تفشل بالتحميل على جهاز
// المستخدم فتظهر خريطة خضراء فارغة بلا شوارع أو تفاصيل حقيقية. التطبيق
// أصلاً يستخدم google_maps_flutter بنجاح بشاشة "تحديد موقع السيارة"
// (map_location_picker_screen.dart)، فوحّدنا هذه الشاشة معها لنفس شكل
// خرائط جوجل العادي والموثوق بدل الاعتماد على مزوّد بلاطات مختلف.
class AdMapScreen extends StatelessWidget {
  final Ad ad;
  const AdMapScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    // نفضّل الإحداثيات الحقيقية المخزّنة مع السيارة (latitude/longitude)،
    // وهي أدق موقع فعلي أدخله صاحب الإعلان عند الإضافة. اللجوء لتخمين
    // موقع المدينة النصي (MapUtils) يكون فقط إذا لم تتوفر إحداثيات دقيقة.
    final hasPreciseLocation =
        ad.car.latitude != null &&
        ad.car.longitude != null &&
        (ad.car.latitude != 0 || ad.car.longitude != 0);
    final fallback = MapUtils.getCoordinates(ad.car.location);
    final LatLng coords =
        hasPreciseLocation
            ? LatLng(ad.car.latitude!, ad.car.longitude!)
            : LatLng(fallback.latitude, fallback.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموقع على الخريطة'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!hasPreciseLocation)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: const Text(
                'لا تتوفر إحداثيات دقيقة لهذه السيارة — الموقع المعروض تقريبي لمركز المدينة فقط.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: coords,
                zoom: hasPreciseLocation ? 15 : 12,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('car-location'),
                  position: coords,
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          if (ad.car.location.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ad.car.location)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
