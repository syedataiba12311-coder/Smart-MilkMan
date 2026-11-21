import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class RiderMapPage extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerAddress;
  final String customerPhone;

  const RiderMapPage({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
  });

  @override
  State<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends State<RiderMapPage> {
  late MapController _mapController;
  bool _isLoading = true;
  bool _isMapReady = false;
  String _errorMsg = '';
  GeoPoint? _riderLocation;
  GeoPoint? _customerLocation;
  String _eta = "15-20 min"; // Estimated time
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<firestore.DocumentSnapshot>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initPosition: GeoPoint(latitude: 24.8607, longitude: 67.0011),
    );
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // 1. Ask for Location Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMsg = "Location permissions are denied.";
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = "Location permissions are permanently denied.";
          _isLoading = false;
        });
        return;
      }

      // 2. Get Rider's Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _riderLocation = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Start listening to location updates
      _startLocationUpdates();

      // 3. Set Customer Location
      // Try to fetch real customer location from the order document
      try {
        final orderDoc = await firestore.FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();
            
        if (orderDoc.exists && orderDoc.data() != null) {
          final data = orderDoc.data()!;
          if (data.containsKey('customerLat') && data.containsKey('customerLng')) {
            _customerLocation = GeoPoint(
              latitude: (data['customerLat'] as num).toDouble(),
              longitude: (data['customerLng'] as num).toDouble(),
            );
          }
        }
      } catch (e) {
        debugPrint("Could not fetch customer location: $e");
      }

      // Fallback if not available
      if (_customerLocation == null) {
        _customerLocation = GeoPoint(
          latitude: position.latitude + 0.015,
          longitude: position.longitude + 0.015,
        );
      }

      setState(() {
        _isLoading = false;
        // Update map init position if possible before ready (or wait for onMapIsReady)
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Error getting location: $e";
        _isLoading = false;
      });
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!mounted) return;
      
      final newGeoPoint = GeoPoint(latitude: position.latitude, longitude: position.longitude);
      
      setState(() {
        _riderLocation = newGeoPoint;
      });

      // Update map marker
      if (_isMapReady) {
        _mapController.changeLocation(newGeoPoint);
      }

      // Update Firestore so the customer can track the rider
      firestore.FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'riderLat': position.latitude,
        'riderLng': position.longitude,
      }).catchError((error) {
        debugPrint("Failed to update rider location in Firestore: $error");
      });
    });

    _listenToCustomerLocation();
  }

  void _listenToCustomerLocation() {
    _orderSubscription = firestore.FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((docSnapshot) async {
      if (!mounted) return;
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('customerLat') && data.containsKey('customerLat')) {
          final newCustomerLocation = GeoPoint(
            latitude: (data['customerLat'] as num).toDouble(),
            longitude: (data['customerLng'] as num).toDouble(),
          );

          if (_customerLocation != null &&
              (_customerLocation!.latitude != newCustomerLocation.latitude ||
                  _customerLocation!.longitude != newCustomerLocation.longitude)) {
            
            setState(() {
              _customerLocation = newCustomerLocation;
            });

            if (_isMapReady) {
              // Note: flutter_osm_plugin doesn't easily let us change a specific marker unless we tracked it.
              // We redraw the whole thing or try to change location marker.
              // Assuming _customerLocation is the dest
              try {
                await _mapController.addMarker(
                  newCustomerLocation,
                  markerIcon: const MarkerIcon(
                    icon: Icon(Icons.location_on, color: Colors.red, size: 48),
                  ),
                );
                // Also redraw road if both exist
                if (_riderLocation != null) {
                   await _mapController.drawRoad(
                    _riderLocation!,
                    newCustomerLocation,
                    roadType: RoadType.car,
                    roadOption: const RoadOption(
                      roadColor: AppTheme.primaryColor,
                      roadWidth: 10,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Map update error: $e");
              }
            }
          }
        }
      }
    });
  }

  Future<void> _onMapReady(bool isReady) async {
    if (!mounted) return;
    if (isReady && _riderLocation != null && _customerLocation != null) {
      setState(() {
        _isMapReady = true;
      });

      try {
        await _mapController.changeLocation(_riderLocation!);

        // Add Marker for Rider
        await _mapController.addMarker(
          _riderLocation!,
          markerIcon: const MarkerIcon(
            iconWidget: SizedBox(
              width: 50,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Icon(Icons.delivery_dining, color: AppTheme.primaryColor, size: 30),
              ),
            ),
          ),
        );

        // Add Marker for Customer
        await _mapController.addMarker(
          _customerLocation!,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.location_on, color: Colors.red, size: 48),
          ),
        );

        // Draw Road (Route)
        await _mapController.drawRoad(
          _riderLocation!,
          _customerLocation!,
          roadType: RoadType.car,
          roadOption: const RoadOption(
            roadColor: AppTheme.primaryColor,
            roadWidth: 10,
          ),
        );

        // Zoom to fit both points
        await _mapController.zoomToBoundingBox(
          BoundingBox.fromGeoPoints([_riderLocation!, _customerLocation!]),
          paddinInPixel: 50,
        );
      } catch (e) {
        debugPrint("Error setting up map: $e");
      }
    }
  }

  Future<void> _launchDialer() async {
    final Uri launchUri = Uri(scheme: 'tel', path: widget.customerPhone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open dialer")),
      );
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _orderSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text("Tracking Delivery")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Getting your location..."),
            ],
          ),
        ),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text("Tracking Delivery")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _errorMsg,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Navigation", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // THE MAP
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
                    color: Colors.blue,
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

          // OVERLAY UI - BOTTOM BOXES (Estimated Time)
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Delivery Navigation",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        "ETA: $_eta",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.customerAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _infoBox(Icons.person, "Customer", widget.customerName),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _launchDialer,
                          child: _infoBox(Icons.phone, "Call", widget.customerPhone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoBox(Icons.timer, "ETA", _eta),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
