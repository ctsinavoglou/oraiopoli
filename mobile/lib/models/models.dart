import '../core/constants/api_constants.dart';

class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool enabled;
  final String? createdAt;

  User({required this.id, required this.fullName, required this.email,
    required this.phone, required this.role, required this.enabled, this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'], fullName: json['fullName'], email: json['email'],
    phone: json['phone'], role: json['role'], enabled: json['enabled'],
    createdAt: json['createdAt'],
  );
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResult({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['accessToken'], refreshToken: json['refreshToken'],
    user: User.fromJson(json['user']),
  );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int displayOrder;
  final bool active;
  final int? parentId;
  final List<Category>? children;

  Category({required this.id, required this.name, required this.slug,
    this.description, this.imageUrl, required this.displayOrder,
    required this.active, this.parentId, this.children});

  bool get hasChildren => children != null && children!.isNotEmpty;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'], name: json['name'], slug: json['slug'],
    description: json['description'], imageUrl: json['imageUrl'],
    displayOrder: json['displayOrder'] ?? 0, active: json['active'] ?? true,
    parentId: json['parentId'],
    children: json['children'] != null
        ? (json['children'] as List).map((c) => Category.fromJson(c)).toList()
        : null,
  );
}

class Brand {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;

  Brand({required this.id, required this.name, required this.slug, this.logoUrl});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'], name: json['name'], slug: json['slug'], logoUrl: json['logoUrl'],
  );
}

class Product {
  final int id;
  final String name;
  final String slug;
  final String? sku;
  final String? description;
  final double price;
  final double? discountPrice;
  final String? unit;
  final bool active;
  final bool featured;
  final String? thumbnailUrl;
  final String? categoryName;
  final int? categoryId;
  final String? brandName;
  final int stockQuantity;
  final bool inStock;
  final List<ProductImage>? images;

  Product({required this.id, required this.name, required this.slug, this.sku,
    this.description, required this.price, this.discountPrice, this.unit,
    required this.active, required this.featured, this.thumbnailUrl,
    this.categoryName, this.categoryId, this.brandName,
    required this.stockQuantity, required this.inStock, this.images});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'], name: json['name'], slug: json['slug'] ?? '',
    sku: json['sku'], description: json['description'],
    price: (json['price'] as num).toDouble(),
    discountPrice: json['discountPrice'] != null ? (json['discountPrice'] as num).toDouble() : null,
    unit: json['unit'], active: json['active'] ?? true, featured: json['featured'] ?? false,
    thumbnailUrl: json['thumbnailUrl'], categoryName: json['categoryName'],
    categoryId: json['categoryId'], brandName: json['brandName'],
    stockQuantity: json['stockQuantity'] ?? 0, inStock: json['inStock'] ?? false,
    images: json['images'] != null
        ? (json['images'] as List).map((i) => ProductImage.fromJson(i)).toList()
        : null,
  );

  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  String? get resolvedThumbnailUrl {
    if (thumbnailUrl == null || thumbnailUrl!.isEmpty) return null;
    if (thumbnailUrl!.startsWith('/uploads')) return '${ApiConstants.baseUrl}$thumbnailUrl';
    return thumbnailUrl;
  }
}

class ProductImage {
  final int id;
  final String imageUrl;
  final String? altText;
  final int displayOrder;

  ProductImage({required this.id, required this.imageUrl, this.altText, required this.displayOrder});

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: json['id'], imageUrl: json['imageUrl'],
    altText: json['altText'], displayOrder: json['displayOrder'] ?? 0,
  );
}

class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productThumbnail;
  final double originalPrice;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final int stockQuantity;

  CartItem({required this.id, required this.productId, required this.productName,
    this.productThumbnail, required this.originalPrice, required this.unitPrice,
    required this.quantity, required this.subtotal, required this.stockQuantity});

  bool get hasDiscount => unitPrice < originalPrice;

  String? get resolvedProductThumbnail {
    if (productThumbnail == null || productThumbnail!.isEmpty) return null;
    if (productThumbnail!.startsWith('/uploads')) return '${ApiConstants.baseUrl}$productThumbnail';
    return productThumbnail;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'], productId: json['productId'],
    productName: json['productName'], productThumbnail: json['productThumbnail'],
    originalPrice: json['originalPrice'] != null ? (json['originalPrice'] as num).toDouble() : (json['unitPrice'] as num).toDouble(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'],
    subtotal: (json['subtotal'] as num).toDouble(),
    stockQuantity: json['stockQuantity'] ?? 0,
  );
}

class Cart {
  final int id;
  final List<CartItem> items;
  final double totalAmount;
  final int totalItems;

  Cart({required this.id, required this.items, required this.totalAmount, required this.totalItems});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List).map((i) => CartItem.fromJson(i)).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return Cart(
      id: json['id'],
      items: items,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItem({required this.id, required this.productId, required this.productName,
    required this.unitPrice, required this.quantity, required this.subtotal});

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'], productId: json['productId'],
    productName: json['productName'],
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'],
    subtotal: (json['subtotal'] as num).toDouble(),
  );
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String shippingAddress;
  final String? contactPhone;
  final String? notes;
  final List<OrderItem> items;
  final String? createdAt;

  Order({required this.id, required this.orderNumber, required this.status,
    required this.totalAmount, required this.shippingAddress,
    this.contactPhone, this.notes, required this.items, this.createdAt});

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'], orderNumber: json['orderNumber'], status: json['status'],
    totalAmount: (json['totalAmount'] as num).toDouble(),
    shippingAddress: json['shippingAddress'], contactPhone: json['contactPhone'],
    notes: json['notes'],
    items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    createdAt: json['createdAt'],
  );
}

class Address {
  final int id;
  final String label;
  final String addressLine;
  final String? city;
  final String? postalCode;
  final String? country;
  final bool isDefault;

  Address({required this.id, required this.label, required this.addressLine,
    this.city, this.postalCode, this.country, required this.isDefault});

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'], label: json['label'], addressLine: json['addressLine'],
    city: json['city'], postalCode: json['postalCode'], country: json['country'],
    isDefault: json['isDefault'] ?? json['default'] ?? false,
  );
}

class Banner {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;

  Banner({required this.id, required this.title, this.subtitle,
    required this.imageUrl, this.linkUrl});

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
    id: json['id'], title: json['title'], subtitle: json['subtitle'],
    imageUrl: json['imageUrl'], linkUrl: json['linkUrl'],
  );
}

class Promotion {
  final int id;
  final String title;
  final String? description;
  final String? code;
  final String? imageUrl;

  Promotion({required this.id, required this.title, this.description,
    this.code, this.imageUrl});

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
    id: json['id'], title: json['title'], description: json['description'],
    code: json['code'], imageUrl: json['imageUrl'],
  );
}

