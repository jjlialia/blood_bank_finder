library;

import '../services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackfillService {
  final LocationService _locationSvc = LocationService();

  /// Hospital Metadata Sync.
  /// by super admin
  Future<int> syncAllHospitals() async {
    int updatedCount = 0;

    // Fetch every hospital record from the database.
    final snapshot = await FirebaseFirestore.instance
        .collection('hospitals')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String? existingRegion = data['region'];
      final String island = data['islandGroup'] ?? '';
      final String city = data['city'] ?? '';

      if (existingRegion == null || existingRegion.isEmpty) {
        if (island.isNotEmpty && city.isNotEmpty) {
          final regions = await _locationSvc.getRegionsByIsland(island);
          String? foundRegion;

          for (var reg in regions) {
            final citiesInReg = await _locationSvc.getCitiesAndMunicipalities(
              reg['code'],
            );
            if (citiesInReg.any((c) => c['name'] == city)) {
              foundRegion = reg['name'];
              break; // Match found
            }
          }

          if (foundRegion != null) {
            await doc.reference.update({'region': foundRegion});
            updatedCount++;
          }
        }
      }
    }

    return updatedCount;
  }
}
