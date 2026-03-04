import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui'; // For ImageFilter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF546E7A), // Blue-grey seed from the photo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LocationScreen(),
      },
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _locationMessage = "Ready to find your location";
  bool _isLoading = false;
  Position? _currentPosition;
  final List<Map<String, dynamic>> _savedLocations = [];

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationMessage = "Acquiring satellite signal...";
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationMessage = "Location Acquired";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error: $e";
        _isLoading = false;
      });
    }
  }

  void _saveLocation() {
    if (_currentPosition != null) {
      setState(() {
        _savedLocations.insert(0, {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'altitude': _currentPosition!.altitude,
          'timestamp': DateTime.now(),
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved to log!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Location Explorer',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFCFD8DC), // Foggy grey-blue top
              Color(0xFFECEFF1), // Lighter bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Status Card
                        Card(
                          elevation: 8,
                          shadowColor: Colors.black26,
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.landscape_rounded,
                                  size: 64,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _locationMessage,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                ),
                                if (_currentPosition != null) ...[
                                  const SizedBox(height: 24),
                                  _buildDataRow(Icons.explore, "Latitude",
                                      "${_currentPosition!.latitude.toStringAsFixed(5)}°"),
                                  const Divider(height: 24),
                                  _buildDataRow(Icons.explore_outlined, "Longitude",
                                      "${_currentPosition!.longitude.toStringAsFixed(5)}°"),
                                  const Divider(height: 24),
                                  _buildDataRow(Icons.height, "Altitude",
                                      "${_currentPosition!.altitude.toStringAsFixed(1)} m"),
                                  const Divider(height: 24),
                                  _buildDataRow(Icons.speed, "Speed",
                                      "${_currentPosition!.speed.toStringAsFixed(1)} m/s"),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isLoading
                                ? const CircularProgressIndicator()
                                : FloatingActionButton.extended(
                                    onPressed: _getCurrentLocation,
                                    icon: const Icon(Icons.my_location),
                                    label: const Text('Locate Me'),
                                    heroTag: 'locate',
                                  ),
                            if (_currentPosition != null) ...[
                              const SizedBox(width: 16),
                              FloatingActionButton.extended(
                                onPressed: _saveLocation,
                                icon: const Icon(Icons.bookmark_add),
                                label: const Text('Save'),
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                heroTag: 'save',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Saved Locations List
              if (_savedLocations.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                "Saved Spots",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _savedLocations.length,
                            itemBuilder: (context, index) {
                              final loc = _savedLocations[index];
                              final date = loc['timestamp'] as DateTime;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.place,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    "${loc['latitude'].toStringAsFixed(4)}, ${loc['longitude'].toStringAsFixed(4)}",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    "${date.hour}:${date.minute.toString().padLeft(2, '0')} • Alt: ${loc['altitude'].toStringAsFixed(0)}m",
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
