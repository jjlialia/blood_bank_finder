/// FILE: backfill_service.dart
///
/// DESCRIPTION:
/// This service is an administrative utility used to maintain data integrity
/// across the hospital directory. Specifically, it identifies hospitals that
/// are missing 'region' metadata and attempts to automatically fill that data
/// by cross-referencing their 'city' and 'islandGroup' with the PSGC location API.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - Firestore: Fetches every document in the 'hospitals' collection.
///    - 'LocationService': Queries the PSGC API to find which Region a City belongs to.
/// 2. PROCESSING:
///    - Iterates through all hospitals.
///    - If 'region' is null/empty, it performs a cascading search:
///      a. Gets all Regions for the hospital's Island Group.
///      b. For each Region, fetches its Cities.
///      c. If a match for the hospital's City is found, it identifies the correct Region.
/// 3. SENDS DATA TO:
///    - Firestore (Direct Update): Writes the missing 'region' field back to the document.
/// 4. OUTPUTS/RESPONSES:
///    - Returns 'int': The total number of hospital records successfully updated.
library;

import '../services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackfillService {
  final LocationService _locationSvc = LocationService();

  /// CORE LOGIC: Hospital Metadata Sync.
  /// This is triggered by the Super Admin via the 'Sync' icon on the Manage Hospitals screen.
  Future<int> syncAllHospitals() async {
    int updatedCount = 0;

    // STEP 1: Fetch every hospital record from the database.
    final snapshot = await FirebaseFirestore.instance
        .collection('hospitals')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String? existingRegion = data['region'];
      final String island = data['islandGroup'] ?? '';
      final String city = data['city'] ?? '';

      // STEP 2: Logic Gate - Only proceed if the 'region' field is actually missing.
      if (existingRegion == null || existingRegion.isEmpty) {
        if (island.isNotEmpty && city.isNotEmpty) {
          // STEP 3: Cross-referencing - Find which region contains this specific city.
          final regions = await _locationSvc.getRegionsByIsland(island);
          String? foundRegion;

          for (var reg in regions) {
            // This requires a network call to fetch cities for each potential region.
            final citiesInReg = await _locationSvc.getCitiesAndMunicipalities(
              reg['code'],
            );
            if (citiesInReg.any((c) => c['name'] == city)) {
              foundRegion = reg['name'];
              break; // Match found!
            }
          }

          // STEP 4: Persistence - If a match was found, update the document in Firestore.
          if (foundRegion != null) {
            await doc.reference.update({'region': foundRegion});
            updatedCount++;
          }
        }
      }
    }

    // OUTPUT: The total count of fixed records, used to show a success snackbar.
    return updatedCount;
  }
}
