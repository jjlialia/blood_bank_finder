import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../hospital/domain/entities/hospital.dart';
import 'package:geolocator/geolocator.dart';

class HospitalMapView extends StatefulWidget {
  final List<HospitalEntity> hospitals;
  final Function(HospitalEntity) onHospitalTap;
  final LatLng? initialCenter;
  final double initialZoom;

  const HospitalMapView({
    super.key,
    required this.hospitals,
    required this.onHospitalTap,
    this.initialCenter,
    this.initialZoom = 12,
  });

  @override
  State<HospitalMapView> createState() => _HospitalMapViewState();
}

class _HospitalMapViewState extends State<HospitalMapView> {
  final MapController _mapController = MapController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void didUpdateWidget(HospitalMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCenter != oldWidget.initialCenter && 
        widget.initialCenter != null) {
      _mapController.move(widget.initialCenter!, widget.initialZoom);
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        // If no initial center provided, move map to user location
        if (widget.initialCenter == null) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            widget.initialZoom,
          );
        }
      }
    } catch (e) {
      debugPrint('Error determining location: $e');
    }
  }

  List<Marker> _buildMarkers() {
    return widget.hospitals.map((h) {
      return Marker(
        point: LatLng(h.latitude, h.longitude),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => widget.onHospitalTap(h),
          child: Column(
            children: [
              Icon(
                Icons.local_hospital,
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final startCenter = widget.initialCenter ?? 
        (_currentPosition != null 
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : const LatLng(14.5995, 120.9842)); // Manila City Center

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: startCenter,
        initialZoom: widget.initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.blood_bank_finder',
        ),
        MarkerLayer(markers: _buildMarkers()),
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

