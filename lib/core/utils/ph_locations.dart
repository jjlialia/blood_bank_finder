class PhLocationData {
  static const List<String> islandGroups = ['Luzon', 'Visayas', 'Mindanao'];

  static const Map<String, List<String>> _cities = {
    'Luzon': [
      'Metro Manila',
      'Baguio',
      'Angeles',
      'Puerto Princesa',
      'Legazpi',
    ],
    'Visayas': ['Cebu City', 'Iloilo City', 'Bacolod', 'Tacloban', 'Dumaguete'],
    'Mindanao': [
      'Davao City',
      'Cagayan de Oro',
      'Zamboanga City',
      'General Santos',
      'Butuan',
    ],
  };

  static const Map<String, List<String>> _barangays = {
    'Metro Manila': [
      'Barangay 1',
      'Barangay 2',
      'Barangay 3',
      'Central',
      'Diliman',
    ],
    'Cebu City': ['Lahug', 'Mabolo', 'Guadalupe', 'Banilad', 'Talamban'],
    'Davao City': ['Buhangin', 'Talomo', 'Agdao', 'Toril', 'Bunawan'],
    // Add default barangays for other cities to avoid empty lists
  };

  static List<String> getCitiesForIsland(String island) {
    return _cities[island] ?? [];
  }

  static List<String> getBarangaysForCity(String city) {
    if (_barangays.containsKey(city)) {
      return _barangays[city]!;
    }
    // Generic barangays for cities not explicitly mapped
    return ['Barangay A', 'Barangay B', 'Barangay C'];
  }
}
