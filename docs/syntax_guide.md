# Blood Bank Finder - Syntax Guide

This guide explains the Dart and Flutter syntax used in the Philippine-enhanced version of the app.

## 1. Hierarchical Data (Maps & Lists)
In `ph_locations.dart`, we use nested Maps to represent relationships:
- `Map<String, List<String>>`: Maps an Island Group to its Cities.
- `Map<String, List<String>>`: Maps a City to its Barangays.
This allows for dynamic filtering without a backend.

## 2. Stepper Widget
In `DonateBloodScreen`, we use the `Stepper` widget:
- `currentStep`: Tracks the active step.
- `onStepContinue`: Logic to advance or submit.
- `Step`: Individual segments containing titles and content Widgets.

## 3. Modal Bottom Sheet
In `FindBloodBankScreen`, `showModalBottomSheet` is used to show hospital details without leaving the page.
- `mainAxisSize: MainAxisSize.min`: Ensures the sheet only takes up as much space as needed.
- `shape`: Custom rounded borders for a premium feel.

## 4. Hierarchical Callbacks
The `PhLocationPicker` uses a callback function:
```dart
final Function(String? island, String? city, String? barangay) onLocationChanged;
```
This notifies the parent widget whenever the selection in any of the three dropdowns changes.

## 5. List Filtering
We use `.where()` to filter results in real-time:
```dart
final filteredHospitals = _hospitals.where((h) {
  final matchesCity = _selectedCity == null || h['city'] == _selectedCity;
  return matchesCity;
}).toList();
```
This is efficient for client-side searching and filtering.
