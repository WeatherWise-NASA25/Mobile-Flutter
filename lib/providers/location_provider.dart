import 'package:flutter/foundation.dart';
import '../models/location_model.dart';

class LocationProvider extends ChangeNotifier {
  LocationModel? _selectedLocation;
  List<LocationModel> _recentLocations = [];
  List<LocationModel> _favoriteLocations = [];

  LocationModel? get selectedLocation => _selectedLocation;
  List<LocationModel> get recentLocations => _recentLocations;
  List<LocationModel> get favoriteLocations => _favoriteLocations;

  void setSelectedLocation(LocationModel location) {
    _selectedLocation = location;
    _addToRecentLocations(location);
    notifyListeners();
  }

  void _addToRecentLocations(LocationModel location) {
    // Remove if already exists
    _recentLocations.removeWhere((l) => l == location);
    
    // Add to beginning
    _recentLocations.insert(0, location.copyWith(selectedAt: DateTime.now()));
    
    // Keep only last 10 locations
    if (_recentLocations.length > 10) {
      _recentLocations = _recentLocations.take(10).toList();
    }
  }

  void addToFavorites(LocationModel location) {
    if (!_favoriteLocations.contains(location)) {
      _favoriteLocations.add(location);
      notifyListeners();
    }
  }

  void removeFromFavorites(LocationModel location) {
    _favoriteLocations.removeWhere((l) => l == location);
    notifyListeners();
  }

  bool isFavorite(LocationModel location) {
    return _favoriteLocations.contains(location);
  }

  void clearSelectedLocation() {
    _selectedLocation = null;
    notifyListeners();
  }

  void clearRecentLocations() {
    _recentLocations.clear();
    notifyListeners();
  }
}