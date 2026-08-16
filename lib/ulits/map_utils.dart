import 'package:latlong2/latlong.dart';

class MapUtils {
  static LatLng getCoordinates(String location) {
    final key = location.toLowerCase();

    if (key.contains('دمشق')) {
      return const LatLng(33.5138, 36.2765);
    }
    if (key.contains('حلب')) {
      return const LatLng(36.2021, 37.1343);
    }
    if (key.contains('اللاذقية')) {
      return const LatLng(35.5319, 35.7834);
    }
    if (key.contains('حمص')) {
      return const LatLng(34.7304, 36.7097);
    }
    if (key.contains('حماه') || key.contains('حماة')) {
      return const LatLng(35.1318, 36.7578);
    }
    if (key.contains('دير الزور')) {
      return const LatLng(35.3350, 40.1431);
    }
    if (key.contains('طرطوس')) {
      return const LatLng(34.8974, 35.8864);
    }
    if (key.contains('درعا')) {
      return const LatLng(32.5140, 36.1057);
    }
    if (key.contains('درِعا')) {
      return const LatLng(32.5140, 36.1057);
    }
    return const LatLng(33.5138, 36.2765);
  }
}
