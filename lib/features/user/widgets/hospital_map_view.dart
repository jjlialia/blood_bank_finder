import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/hospital_model.dart';
import 'package:geolocator/geolocator.dart';

class HospitalMapView extends StatefulWidget {
  final List<HospitalModel> hospitals;
  final Function(HospitalModel) onHospitalTap;
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
  GoogleMapController? _mapController;
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
        widget.initialCenter != null && 
        _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.initialCenter!, widget.initialZoom),
      );
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
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
    }
  }

  Set<Marker> _buildMarkers() {
    return widget.hospitals.map((h) {
      return Marker(
        markerId: MarkerId(h.id ?? h.name),
        position: LatLng(h.latitude, h.longitude),
        infoWindow: InfoWindow(
          title: h.name,
          snippet: h.address,
          onTap: () => widget.onHospitalTap(h),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter ?? (_currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(14.5995, 120.9842)), // Default to Manila
            zoom: widget.initialZoom,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: _buildMarkers(),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
        if (_currentPosition == null)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Loading Location...'),
              ),
            ),
          ),
      ],
    );
  }
}
