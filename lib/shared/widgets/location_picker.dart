import 'package:flutter/material.dart';
import '../../core/utils/ph_locations.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedIsland,
          decoration: const InputDecoration(labelText: 'Island Group'),
          items: PhLocationData.islandGroups
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedIsland = v;
              _selectedCity = null;
              _selectedBarangay = null;
            });
            widget.onLocationChanged(
              _selectedIsland,
              _selectedCity,
              _selectedBarangay,
            );
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          decoration: const InputDecoration(labelText: 'City'),
          items: PhLocationData.getCitiesForIsland(
            _selectedIsland ?? '',
          ).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: _selectedIsland == null
              ? null
              : (v) {
                  setState(() {
                    _selectedCity = v;
                    _selectedBarangay = null;
                  });
                  widget.onLocationChanged(
                    _selectedIsland,
                    _selectedCity,
                    _selectedBarangay,
                  );
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedBarangay,
          decoration: const InputDecoration(labelText: 'Barangay'),
          items: PhLocationData.getBarangaysForCity(
            _selectedCity ?? '',
          ).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: _selectedCity == null
              ? null
              : (v) {
                  setState(() {
                    _selectedBarangay = v;
                  });
                  widget.onLocationChanged(
                    _selectedIsland,
                    _selectedCity,
                    _selectedBarangay,
                  );
                },
        ),
      ],
    );
  }
}
