import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/location_provider.dart';

class PhLocationPicker extends StatefulWidget {
  final Function(String? island, String? city, String? barangay)
  onLocationChanged;

  const PhLocationPicker({super.key, required this.onLocationChanged});

  @override
  State<PhLocationPicker> createState() => _PhLocationPickerState();
}

class _PhLocationPickerState extends State<PhLocationPicker> {
  String? _selectedIsland;
  String? _selectedCity;
  String? _selectedBarangay;

  List<String> _cities = [];
  List<String> _barangays = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchIslandGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedIsland,
              decoration: const InputDecoration(labelText: 'Island Group'),
              items: locationProvider.islandGroups
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                final cities = await locationProvider.getCities(v);
                setState(() {
                  _selectedIsland = v;
                  _selectedCity = null;
                  _selectedBarangay = null;
                  _cities = cities;
                  _barangays = [];
                });
                widget.onLocationChanged(v, null, null);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(labelText: 'City'),
              items: _cities
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: _selectedIsland == null
                  ? null
                  : (v) async {
                      if (v == null) return;
                      final barangays = await locationProvider.getBarangays(v);
                      setState(() {
                        _selectedCity = v;
                        _selectedBarangay = null;
                        _barangays = barangays;
                      });
                      widget.onLocationChanged(_selectedIsland, v, null);
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBarangay,
              decoration: const InputDecoration(labelText: 'Barangay'),
              items: _barangays
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: _selectedCity == null
                  ? null
                  : (v) {
                      setState(() {
                        _selectedBarangay = v;
                      });
                      widget.onLocationChanged(
                        _selectedIsland,
                        _selectedCity,
                        v,
                      );
                    },
            ),
          ],
        );
      },
    );
  }
}
