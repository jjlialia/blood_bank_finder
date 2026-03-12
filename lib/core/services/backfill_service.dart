import '../services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackfillService {
  final LocationService _locationSvc = LocationService();

  Future<int> syncAllHospitals() async {
    int updatedCount = 0;
    
    // 1. Get all hospitals (including those without regions)
    final snapshot = await FirebaseFirestore.instance.collection('hospitals').get();
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String? existingRegion = data['region'];
      final String island = data['islandGroup'] ?? '';
      final String city = data['city'] ?? '';
      
      // 2. Only update if region is missing or empty
      if (existingRegion == null || existingRegion.isEmpty) {
        if (island.isNotEmpty && city.isNotEmpty) {
          // 3. Find region for this city
          final regions = await _locationSvc.getRegionsByIsland(island);
          String? foundRegion;
          
          for (var reg in regions) {
            final citiesInReg = await _locationSvc.getCitiesAndMunicipalities(reg['code']);
            if (citiesInReg.any((c) => c['name'] == city)) {
              foundRegion = reg['name'];
              break;
            }
          }
          
          // 4. Update the document
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
