import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/order_repository.dart';
import '../../models/models.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});
  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _addressLineCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _mapController = MapController();

  bool _saving = false;
  bool _geocoding = false;
  Address? _existingAddress;
  bool _initialized = false;

  // Default to store location (will be updated from store settings)
  LatLng _markerPosition = const LatLng(37.9560, 23.7012);
  double _storeLatitude = 37.9560;
  double _storeLongitude = 23.7012;
  double _maxDeliveryKm = 10.0;

  double? _distanceKm;
  bool _exceedsMaxDistance = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressLineCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _countryCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _initializeFromAddress(Address address) {
    _existingAddress = address;
    _labelCtrl.text = address.label;
    _addressLineCtrl.text = address.addressLine;
    _cityCtrl.text = address.city ?? '';
    _postalCodeCtrl.text = address.postalCode ?? '';
    _countryCtrl.text = address.country ?? '';
    if (address.latitude != null && address.longitude != null) {
      _markerPosition = LatLng(address.latitude!, address.longitude!);
    }
  }

  void _loadStoreSettings(Map<String, String> info) {
    _storeLatitude = double.tryParse(info['store_latitude'] ?? '0') ?? 37.9560;
    _storeLongitude = double.tryParse(info['store_longitude'] ?? '0') ?? 23.7012;
    _maxDeliveryKm = double.tryParse(info['max_delivery_km'] ?? '10') ?? 10.0;
  }

  /// Geocode the current address text fields using Nominatim (OpenStreetMap)
  /// and move the map + marker to the result.
  Future<void> _geocodeAddress() async {
    final addressLine = _addressLineCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final postalCode = _postalCodeCtrl.text.trim();
    final country = _countryCtrl.text.trim();

    final parts = [addressLine, city, postalCode, country].where((s) => s.isNotEmpty);
    if (parts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an address first'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }

    setState(() => _geocoding = true);
    try {
      final dio = Dio();

      // Use structured search for better accuracy with house numbers
      final params = <String, String>{
        'format': 'json',
        'limit': '1',
        'addressdetails': '1',
      };
      if (addressLine.isNotEmpty) params['street'] = addressLine;
      if (city.isNotEmpty) params['city'] = city;
      if (postalCode.isNotEmpty) params['postalcode'] = postalCode;
      if (country.isNotEmpty) params['country'] = country;

      var res = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: params,
        options: Options(headers: {'User-Agent': 'OraiapoliApp/1.0'}),
      );

      // If structured search found nothing, fall back to free-form query
      if ((res.data as List).isEmpty) {
        final query = parts.join(', ');
        res = await dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': query,
            'format': 'json',
            'limit': '1',
          },
          options: Options(headers: {'User-Agent': 'OraiapoliApp/1.0'}),
        );
      }

      final results = res.data as List;
      if (results.isNotEmpty) {
        final lat = double.parse(results[0]['lat']);
        final lon = double.parse(results[0]['lon']);
        final newPos = LatLng(lat, lon);
        setState(() {
          _markerPosition = newPos;
        });
        _mapController.move(newPos, 16.0);
        _updateDistance();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address not found. Try adjusting the details or move the pin manually.'), backgroundColor: AppColors.warning),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geocoding failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _geocoding = false);
  }

  /// Haversine distance in kilometers
  double _haversineDistance(LatLng from, LatLng to) {
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(to.latitude - from.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(from.latitude)) * cos(_degToRad(to.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _updateDistance() {
    final storePos = LatLng(_storeLatitude, _storeLongitude);
    final dist = _haversineDistance(storePos, _markerPosition);
    setState(() {
      _distanceKm = dist;
      _exceedsMaxDistance = dist > _maxDeliveryKm;
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final data = {
        'label': _labelCtrl.text.trim(),
        'addressLine': _addressLineCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'postalCode': _postalCodeCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'isDefault': true,
        'latitude': _markerPosition.latitude,
        'longitude': _markerPosition.longitude,
      };

      final repo = ref.read(orderRepositoryProvider);
      if (_existingAddress != null) {
        await repo.updateAddress(_existingAddress!.id, data);
      } else {
        await repo.createAddress(data);
      }

      ref.invalidate(addressesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);
    final storeInfoAsync = ref.watch(storeInfoProvider);

    // Load store settings when available
    storeInfoAsync.whenData((info) {
      _loadStoreSettings(info);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Address')),
      body: addressesAsync.when(
        data: (addresses) {
          // Initialize form from existing address once
          if (!_initialized) {
            if (addresses.isNotEmpty) {
              _initializeFromAddress(addresses.first);
            } else {
              // Default values for new address
              _labelCtrl.text = 'Σπίτι';
              _countryCtrl.text = 'Ελλάδα';
            }
            _initialized = true;
            // Calculate initial distance
            WidgetsBinding.instance.addPostFrameCallback((_) => _updateDistance());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address form fields
                  const Text('Address Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'e.g. Home, Work',
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Label is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressLineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Street & number',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _countryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),

                  // Find on Map button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _geocoding ? null : _geocodeAddress,
                      icon: _geocoding
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search, size: 20),
                      label: const Text('Find on Map'),
                    ),
                  ),

                  // Map section
                  const SizedBox(height: 24),
                  const Text('Verify Location on Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the map to move the pin, or use "Find on Map" above',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // Map widget
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 300,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _markerPosition,
                          initialZoom: 15.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _markerPosition = point;
                            });
                            _updateDistance();
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.oraiopoli.app',
                          ),
                          MarkerLayer(
                            markers: [
                              // User's address marker
                              Marker(
                                point: _markerPosition,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                              ),
                              // Store marker
                              Marker(
                                point: LatLng(_storeLatitude, _storeLongitude),
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.store, color: AppColors.primary, size: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Distance info
                  const SizedBox(height: 16),
                  if (_distanceKm != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _exceedsMaxDistance
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _exceedsMaxDistance
                              ? AppColors.error.withValues(alpha: 0.4)
                              : AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _exceedsMaxDistance ? Icons.error_outline : Icons.check_circle_outline,
                            color: _exceedsMaxDistance ? AppColors.error : AppColors.success,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _exceedsMaxDistance
                                  ? 'Your address is ${_distanceKm!.toStringAsFixed(1)} km away. We deliver up to ${_maxDeliveryKm.toStringAsFixed(0)} km. Unfortunately, we cannot deliver to this address.'
                                  : 'Distance from store: ${_distanceKm!.toStringAsFixed(1)} km — Within delivery range ✓',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _exceedsMaxDistance ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveAddress,
                      icon: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_existingAddress != null ? 'Update Address' : 'Save Address'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load addresses')),
      ),
    );
  }
}

