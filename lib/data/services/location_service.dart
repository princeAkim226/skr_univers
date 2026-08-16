import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentAddress;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;

  /// Demande les permissions de localisation
  Future<bool> requestLocationPermission() async {
    try {
      // Vérifier si la localisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés');
      }

      // Demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation définitivement refusée');
      }

      return true;
    } catch (e) {
      print('Erreur lors de la demande de permission: $e');
      return false;
    }
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Obtenir l'adresse à partir des coordonnées
      if (_currentPosition != null) {
        await _getAddressFromPosition(_currentPosition!);
      }

      return _currentPosition;
    } catch (e) {
      print('Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Obtient l'adresse à partir des coordonnées
  Future<String?> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.locality}, ${place.administrativeArea}';
        return _currentAddress;
      }
    } catch (e) {
      print('Erreur lors de l\'obtention de l\'adresse: $e');
    }
    return null;
  }

  /// Calcule la distance entre deux points en kilomètres
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Obtient les produits les plus proches
  Future<List<Map<String, dynamic>>> getNearbyProducts(
    List<Map<String, dynamic>> products,
    {double maxDistanceKm = 50.0}
  ) async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) return products;

      List<Map<String, dynamic>> nearbyProducts = [];

      for (var product in products) {
        // Vérifier si le produit a des coordonnées
        if (product['latitude'] != null && product['longitude'] != null) {
          double distance = calculateDistance(
            position.latitude,
            position.longitude,
            product['latitude'].toDouble(),
            product['longitude'].toDouble(),
          );

          if (distance <= maxDistanceKm) {
            product['distance'] = distance;
            nearbyProducts.add(product);
          }
        }
      }

      // Trier par distance
      nearbyProducts.sort((a, b) => (a['distance'] ?? 0.0).compareTo(b['distance'] ?? 0.0));

      return nearbyProducts;
    } catch (e) {
      print('Erreur lors de l\'obtention des produits proches: $e');
      return products;
    }
  }

  /// Obtient la position de l'utilisateur en arrière-plan
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    );
  }

  /// Vérifie si la localisation est activée
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtient les coordonnées d'une adresse
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'obtention des coordonnées: $e');
    }
    return null;
  }

  /// Formate la distance pour l'affichage
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
}
