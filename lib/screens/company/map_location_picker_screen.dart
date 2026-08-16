import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mators_car/ulits/colors.dart';

/// نتيجة اختيار الموقع التي تُعاد إلى الشاشة السابقة (Navigator.pop)
class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// شاشة كاملة لعرض خريطة جوجل والسماح للمستخدم بالضغط على أي مكان
/// لتحديد إحداثيات السيارة (latitude / longitude)، مع محاولة تحويل
/// الإحداثيات إلى عنوان نصي مقروء عبر Reverse Geocoding.
///
/// الاستخدام:
/// ```dart
/// final result = await Navigator.push<PickedLocation>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => MapLocationPickerScreen(
///       initialLatitude: _latitude,
///       initialLongitude: _longitude,
///     ),
///   ),
/// );
/// if (result != null) {
///   setState(() {
///     _latitude = result.latitude;
///     _longitude = result.longitude;
///     _locationController.text = result.address;
///   });
/// }
/// ```
class MapLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _pickedPosition;
  String? _pickedAddress;
  bool _isLoadingLocation = true;
  bool _isResolvingAddress = false;

  static const LatLng _fallbackPosition = LatLng(33.5138, 36.2765); // دمشق كموقع افتراضي

  @override
  void initState() {
    super.initState();
    _initPosition();
  }

  Future<void> _initPosition() async {
    // إذا كانت هناك إحداثيات محفوظة مسبقاً (تعديل موقع سابق) نستخدمها مباشرة
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      final initial = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      setState(() {
        _pickedPosition = initial;
        _isLoadingLocation = false;
      });
      await _resolveAddress(initial);
      return;
    }

    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        setState(() {
          _pickedPosition = _fallbackPosition;
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final current = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedPosition = current;
        _isLoadingLocation = false;
      });
      await _resolveAddress(current);
    } catch (_) {
      setState(() {
        _pickedPosition = _fallbackPosition;
        _isLoadingLocation = false;
      });
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() {
      _isResolvingAddress = true;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();
        setState(() {
          _pickedAddress = parts.isNotEmpty
              ? parts.join('، ')
              : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
      setState(() {
        _pickedAddress =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _pickedPosition = position;
    });
    await _resolveAddress(position);
  }

  Future<void> _goToMyLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final current = LatLng(position.latitude, position.longitude);
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(current, 15));
    setState(() {
      _pickedPosition = current;
    });
    await _resolveAddress(current);
  }

  void _confirmSelection() {
    if (_pickedPosition == null) return;
    Navigator.pop(
      context,
      PickedLocation(
        latitude: _pickedPosition!.latitude,
        longitude: _pickedPosition!.longitude,
        address: _pickedAddress ??
            '${_pickedPosition!.latitude.toStringAsFixed(5)}, '
                '${_pickedPosition!.longitude.toStringAsFixed(5)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد موقع السيارة'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedPosition ?? _fallbackPosition,
                    zoom: 14.5,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                  },
                  onTap: _onMapTapped,
                  markers: _pickedPosition == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('picked-location'),
                            position: _pickedPosition!,
                          ),
                        },
                ),
                Positioned(
                  right: 16,
                  bottom: 170,
                  child: FloatingActionButton(
                    heroTag: 'myLocationBtn',
                    backgroundColor: Colors.white,
                    onPressed: _goToMyLocation,
                    child: const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _isResolvingAddress
                                    ? const Text('جارِ تحديد العنوان...')
                                    : Text(
                                        _pickedAddress ?? 'اضغط على الخريطة لاختيار الموقع',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                _pickedPosition == null ? null : _confirmSelection,
                            style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                              backgroundColor: AppColors.primaryNavy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'تأكيد هذا الموقع',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
