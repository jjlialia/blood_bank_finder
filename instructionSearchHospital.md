# Blood Bank Finder: Hospital Search Lifecycle

This guide explains the step-by-step procedures for searching, filtering, and locating hospitals, including the code and file locations for each step.

---

## 1. Searching by Name (The Search Bar)

This operation allows users to find a specific hospital using text input.

### Step 1: User types in the search bar
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
The user enters text (e.g., "City Hospital"). The `onChanged` event updates the local state:
```dart
onChanged: (v) => setState(() => _searchQuery = v),
```

### Step 2: Real-time Filtering
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
The `StreamBuilder` automatically filters the list of hospitals fetched from the database based on the search query:
```dart
final hospitals = (snapshot.data ?? [])
    .where((h) => h.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    .toList();
```

---

## 2. Location Filtering (The Hierarchical Picks)

This operation narrows down results to a specific region or city.

### Step 1: User selects a location filter
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
When you tap a filter chip (like "Island" or "City"), it opens a picker:
```dart
onTap: () => _showLocationPicker(context, 'region'),
```

### Step 2: Fetching Geographic Data
**File:** [lib/core/services/location_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/location_service.dart)
The app calls an external API (PSGC Cloud) to get the list of regions or cities:
```dart
Future<List<Map<String, dynamic>>> getRegionsByIsland(String island) async {
  final allRegions = await getRegions();
  final allowedCodes = islandGroupMapping[island] ?? [];
  return allRegions.where((r) => allowedCodes.contains(r['code'])).toList();
}
```

### Step 3: Stream Update
**File:** [lib/core/services/database_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/database_service.dart)
Once a location is selected, the database query is updated to ONLY fetch hospitals in that area:
```dart
if (city != null) {
  query = query.where('city', isEqualTo: city);
}
return query.snapshots(); // Firestore automatically sends matching hospitals
```

---

## 3. Map Synchronization (Geocoding)

This operation moves the map camera to the selected city or region.

### Step 1: Requesting Coordinates
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
The app sends the name of the place to the `ApiService`:
```dart
final loc = await _api.getCoordinatesFromAddress(query);
```

### Step 2: Address to Coordinates Conversion
**File:** [lib/core/services/api_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/api_service.dart)
The `ApiService` converts the text (e.g., "Cebu City") into Latitude and Longitude using Google Maps API or system services:
```dart
final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey';
// Returns Lat/Lng coordinates
```

### Step 3: Fly to Location
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
The map camera moves to the new center point:
```dart
setState(() {
  _mapCenter = LatLng(loc.latitude, loc.longitude);
  _mapZoom = targetZoom;
});
```

---

## 4. Viewing Details

### Step 1: Tapping a Hospital
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
When you tap a hospital card or a pin on the map, the `_showHospitalDetails` function is triggered.

### Step 2: The Bottom Sheet
**File:** [lib/features/user/screens/find_blood_bank_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/find_blood_bank_screen.dart)
A bottom sheet pops up showing the hospital's specific properties from the model:
```dart
void _showHospitalDetails(BuildContext context, HospitalModel h) {
  showModalBottomSheet(
    // Displays h.name, h.address, h.contactNumber, etc.
  );
}
```

---

### Summary of Files Involved:
1.  **UI Level**: `find_blood_bank_screen.dart`
2.  **Logic Level**: `location_service.dart`, `database_service.dart`, `api_service.dart`
3.  **External**: `psgc.cloud` (Geography), `googleapis.com` (Geocoding)
