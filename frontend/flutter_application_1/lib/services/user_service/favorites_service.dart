// lib/services/user_service/favorites_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// Singleton service for managing user favorites via API
class FavoritesService {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();
  factory FavoritesService() => instance;

  // ══════════════════════════════════════════════════════════════════════════
  // 📦 CACHED DATA - Synced with backend
  // ══════════════════════════════════════════════════════════════════════════
  
  List<String> _favoriteServiceIds = [];
  List<String> _favoritePackageIds = [];
  List<String> _favoriteOfferIds = [];
  
  // ══════════════════════════════════════════════════════════════════════════
  // 🔔 NOTIFIERS for reactive UI updates
  // ══════════════════════════════════════════════════════════════════════════
  
  final ValueNotifier<int> servicesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> packagesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> offersCountNotifier = ValueNotifier<int>(0);
  
  /// Total favorites count
  int get totalCount => _favoriteServiceIds.length + _favoritePackageIds.length + _favoriteOfferIds.length;
  
  // ══════════════════════════════════════════════════════════════════════════
  // 🚀 INITIALIZE - Load favorites from backend on app start
  // ══════════════════════════════════════════════════════════════════════════
  
  Future<void> init() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _clearLocal();
        return;
      }
      
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/auth/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _favoriteServiceIds = _parseIds(data['favoriteServices']);
        _favoritePackageIds = _parseIds(data['favoritePackages']);
        _favoriteOfferIds = _parseIds(data['favoriteOffers']);
        
        _updateNotifiers();
        print('✅ Favorites loaded: ${_favoriteServiceIds.length} services, ${_favoritePackageIds.length} packages, ${_favoriteOfferIds.length} offers');
      } else {
        print('❌ Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
  }
  
  List<String> _parseIds(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        if (e is String) return e;
        if (e is Map && e.containsKey('_id')) return e['_id'].toString();
        if (e is Map && e.containsKey('\$oid')) return e['\$oid'].toString();
        return e.toString();
      }).toList();
    }
    return [];
  }
  
  void _updateNotifiers() {
    servicesCountNotifier.value = _favoriteServiceIds.length;
    packagesCountNotifier.value = _favoritePackageIds.length;
    offersCountNotifier.value = _favoriteOfferIds.length;
  }
  
  void _clearLocal() {
    _favoriteServiceIds = [];
    _favoritePackageIds = [];
    _favoriteOfferIds = [];
    _updateNotifiers();
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // ❤️ SERVICES FAVORITES
  // ══════════════════════════════════════════════════════════════════════════
  
  bool isServiceFavorite(String serviceId) => _favoriteServiceIds.contains(serviceId);
  
  List<String> get favoriteServiceIds => List.unmodifiable(_favoriteServiceIds);
  
  Future<bool> toggleServiceFavorite(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/auth/favorites/service/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Toggle locally
        if (_favoriteServiceIds.contains(serviceId)) {
          _favoriteServiceIds.remove(serviceId);
        } else {
          _favoriteServiceIds.add(serviceId);
        }
        _updateNotifiers();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error toggling service favorite: $e');
      return false;
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // 📦 PACKAGES FAVORITES
  // ══════════════════════════════════════════════════════════════════════════
  
  bool isPackageFavorite(String packageId) => _favoritePackageIds.contains(packageId);
  
  List<String> get favoritePackageIds => List.unmodifiable(_favoritePackageIds);
  
  Future<bool> togglePackageFavorite(String packageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/auth/favorites/package/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_favoritePackageIds.contains(packageId)) {
          _favoritePackageIds.remove(packageId);
        } else {
          _favoritePackageIds.add(packageId);
        }
        _updateNotifiers();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error toggling package favorite: $e');
      return false;
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // 🎁 OFFERS FAVORITES
  // ══════════════════════════════════════════════════════════════════════════
  
  bool isOfferFavorite(String offerId) => _favoriteOfferIds.contains(offerId);
  
  List<String> get favoriteOfferIds => List.unmodifiable(_favoriteOfferIds);
  
  Future<bool> toggleOfferFavorite(String offerId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/auth/favorites/offer/$offerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_favoriteOfferIds.contains(offerId)) {
          _favoriteOfferIds.remove(offerId);
        } else {
          _favoriteOfferIds.add(offerId);
        }
        _updateNotifiers();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error toggling offer favorite: $e');
      return false;
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // 🧹 CLEAR ALL - On logout
  // ══════════════════════════════════════════════════════════════════════════
  
  void clearAll() {
    _clearLocal();
    print('🧹 Favorites cleared');
  }
}
