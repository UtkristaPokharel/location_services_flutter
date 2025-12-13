import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GetLocation extends StatefulWidget {
  const GetLocation({super.key});

  @override
  State<GetLocation> createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocation> {
  String locationMessage = "Get your location...";
  double? _latitude;
  double? _longitude;

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationMessage =
          '📍 Location services are disabled. Opening settings...');
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationMessage = '❌ Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => locationMessage =
          '🔒 Location permissions are permanently denied. Please enable from settings.');
      await Geolocator.openAppSettings();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() => locationMessage =
          '📌 Lat: ${position.latitude}, Lon: ${position.longitude}');
      _latitude = position.latitude;
      _longitude = position.longitude;
      _livelocation();
    } catch (e) {
      setState(() => locationMessage = '⚠️ Error getting location: $e');
    }
  }

  void _livelocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((Position position) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        locationMessage =
            '📍 Live Update - Lat: ${position.latitude}, Lon: ${position.longitude}';
      });
    });
  }

  Future<void> _openMap(double latitude, double longitude) async {
    String url;

    // ✅ Use Apple Maps on iPhone, Google Maps on Android
    if (Platform.isAndroid) {
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else if (Platform.isIOS) {
      // Detect simulator
      if (await _isSimulator()) {
        // Fallback to Google Maps in browser for iOS simulator
        url =
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      } else {
        // Real iPhone → use Apple Maps
        url = 'https://maps.apple.com/?q=$latitude,$longitude';
      }
    } else {
      // Other platforms (macOS, web, etc.)
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }

    try {
      await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map: $e')),
      );
    }
  }

  /// Detect if running in iOS Simulator
  Future<bool> _isSimulator() async {
    // iOS simulators run on macOS, not physical devices
    return Platform.isIOS && !Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Get Location"),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(locationMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Get Location"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_latitude == null || _longitude == null) {
                  await _getCurrentLocation();
                }

                if (_latitude != null && _longitude != null) {
                  _openMap(_latitude!, _longitude!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Still unable to get location. Try again.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Live Location"),
            )
          ],
        ),
      ),
    );
  }
}
