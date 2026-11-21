import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class DeliveryTrackingPage extends StatefulWidget {
  const DeliveryTrackingPage({super.key});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage>
    with SingleTickerProviderStateMixin {
  // Coordinates
  // Note: flutter_osm_plugin uses GeoPoint
  final GeoPoint _sourceLocation = GeoPoint(
    latitude: 24.8607,
    longitude: 67.0011,
  ); // Shop
  GeoPoint _destLocation = GeoPoint(
    latitude: 24.9000,
    longitude: 67.0500,
  ); // Customer

  late MapController _mapController;
  GeoPoint? _lastKnownRiderLocation;

  // Animation and Status
  String _deliveryStatus = "Waiting for rider location...";

  // Data Subscription
  StreamSubscription<firestore.QuerySnapshot>? _ordersSubscription;

  // State Variables
  bool _isLoading = true;
  bool _isMapReady = false;
  String _errorMsg = '';
  String _riderName = 'Assigned';
  String _riderPhone = 'N/A';
  bool _hasActiveDelivery = false;
  String? _activeOrderId;

  StreamSubscription<Position>? _customerLocationSubscription;
  @override
  void initState() {
    super.initState();
    _mapController = MapController(initPosition: _sourceLocation);
    _subscribeToOrderUpdates();
  }

  void _subscribeToOrderUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      safeSetState(() {
        _isLoading = false;
        _errorMsg = "User not logged in";
      });
      return;
    }

    _ordersSubscription = firestore.FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Out for Delivery')
        .orderBy('orderDate', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            if (snapshot.docs.isNotEmpty) {
              final data = snapshot.docs.first.data();
              // Check for rider location updates
              if (data.containsKey('riderLat') && data.containsKey('riderLng')) {
                final lat = (data['riderLat'] as num).toDouble();
                final lng = (data['riderLng'] as num).toDouble();
                final newLocation = GeoPoint(latitude: lat, longitude: lng);
                _syncMapMarker(newLocation);
                _deliveryStatus = "Rider is on the way 📍";
              }

              safeSetState(() {
                _hasActiveDelivery = true;
                _activeOrderId = snapshot.docs.first.id;
                _riderName = data['riderAssigned'] ?? 'Assigned';
                _riderPhone = data['riderPhone'] ?? 'N/A';
                _isLoading = false;
              });

              if (_activeOrderId != null) {
                _startCustomerLocationTracking(_activeOrderId!);
              }
            } else {
              safeSetState(() {
                _hasActiveDelivery = false;
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            safeSetState(() {
              _errorMsg = e.toString();
              _isLoading = false;
            });
          },
        );
  }

  Future<void> _syncMapMarker(GeoPoint newLocation) async {
    if (!_isMapReady || !mounted) return;

    try {
      if (_lastKnownRiderLocation != null) {
        // Update marker position
        await _mapController.changeLocationMarker(
          oldLocation: _lastKnownRiderLocation!,
          newLocation: newLocation,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.location_on, color: AppTheme.primaryColor, size: 48),
          ),
        );
      } else {
        // First time adding the marker
        await _mapController.addMarker(
          newLocation,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.location_on, color: AppTheme.primaryColor, size: 48),
          ),
        );
      }
      if (!mounted) return;
      _lastKnownRiderLocation = newLocation;
    } catch (e) {
      debugPrint("Map marker update error: $e");
    }
  }

  Future<void> _startCustomerLocationTracking(String orderId) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _updateCustomerLocationInFirestore(orderId, initialPosition);
      _updateDestLocation(initialPosition);

      _customerLocationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _updateCustomerLocationInFirestore(orderId, position);
        _updateDestLocation(position);
      });
    } catch (e) {
      debugPrint("Error tracking customer location: $e");
    }
  }

  void _updateCustomerLocationInFirestore(String orderId, Position position) {
    firestore.FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'customerLat': position.latitude,
      'customerLng': position.longitude,
    }).catchError((e) => debugPrint("Error updating customer location: $e"));
  }

  void _updateDestLocation(Position position) {
    if (!mounted) return;
    final newGeoPoint = GeoPoint(latitude: position.latitude, longitude: position.longitude);
    if (_isMapReady) {
      _mapController.changeLocationMarker(
        oldLocation: _destLocation,
        newLocation: newGeoPoint,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.location_on, color: Colors.red, size: 48),
        ),
      );
    }
    _destLocation = newGeoPoint;
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    _customerLocationSubscription?.cancel();
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Could not launch dialer for $phoneNumber");
    }
  }

  Future<void> _onMapReady(bool isReady) async {
    if (!mounted) return;
    if (isReady) {
      safeSetState(() {
        _isMapReady = true;
      });

      // Add Static Markers (Shop & User)
      try {
        // Shop Marker
        await _mapController.addMarker(
          _sourceLocation,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.store, color: Colors.blue, size: 48),
          ),
        );
        if (!mounted) return;

        // Customer Marker
        await _mapController.addMarker(
          _destLocation,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.location_on, color: Colors.red, size: 48),
          ),
        );
        if (!mounted) return;

        // Draw Road (Route)
        await _mapController.drawRoad(
          _sourceLocation,
          _destLocation,
          roadType: RoadType.car,
          roadOption: const RoadOption(
            roadColor: AppTheme.primaryColor,
            roadWidth: 10,
          ),
        );
        if (!mounted) return;

        // Zoom to fit
        await _mapController.zoomToBoundingBox(
          BoundingBox.fromGeoPoints([_sourceLocation, _destLocation]),
          paddinInPixel: 50,
        );
      } catch (e) {
        debugPrint("Error initializing map elements: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Error State
    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Text("Error: $_errorMsg")),
      );
    }

    // 3. No Active Delivery State
    if (!_hasActiveDelivery) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                "No Active Delivery",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You don't have any orders in progress.",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Main Map UI
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // MAP LAYER
          OSMFlutter(
            controller: _mapController,
            onMapIsReady: _onMapReady,
            osmOption: OSMOption(
              zoomOption: const ZoomOption(
                initZoom: 14,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(Icons.double_arrow, size: 48),
                ),
              ),
              roadConfiguration: const RoadOption(roadColor: Colors.blueAccent),
            ),
          ),

          // OVERLAY UI (Status Card)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _deliveryStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: null,
                    backgroundColor: Colors.grey.shade200,
                    color: AppTheme.accentColor,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(Icons.person, "Rider", _riderName),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(Icons.timer, "ETA", "10-15 min"),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_riderPhone != 'N/A') {
                              _launchDialer(_riderPhone);
                            }
                          },
                          child: _infoCard(Icons.phone, "Call", _riderPhone),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
