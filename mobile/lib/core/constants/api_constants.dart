import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host; // e.g. "192.168.2.3" or "localhost"
      return 'http://$host:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode ? 'http://192.168.2.3:8080' : 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
  static const String publicProducts = '/api/public/products';
  static const String publicFeatured = '/api/public/products/featured';
  static const String publicSearch = '/api/public/products/search';
  static const String publicFilter = '/api/public/products/filter';
  static const String publicCategories = '/api/public/categories';
  static const String publicBrands = '/api/public/brands';
  static const String publicBanners = '/api/public/banners';
  static const String publicPromotions = '/api/public/promotions';
  static const String publicStoreInfo = '/api/public/store-info';
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh';
  static const String customerProfile = '/api/customer/profile';
  static const String customerAddresses = '/api/customer/addresses';
  static const String customerCart = '/api/customer/cart';
  static const String customerCartItems = '/api/customer/cart/items';
  static const String customerCheckout = '/api/customer/checkout';
  static const String customerOrders = '/api/customer/orders';
  static const String customerValidatePromo = '/api/customer/validate-promo';
  static const String customerFavorites = '/api/customer/favorites';
  static const String customerFavoriteIds = '/api/customer/favorites/ids';
}

