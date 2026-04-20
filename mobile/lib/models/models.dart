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
  final int? buyQuantity;
  final int? getQuantity;
  final String? unit;
  final double? weightQuantity;
  final String? weightUnit;
  final double? pricePerUnit;
  final double? discountPricePerUnit;
  final String? pricePerUnitLabel;
  final bool active;
  final bool featured;
  final String? thumbnailUrl;
  final String? categoryName;
  final int? categoryId;
  final String? brandName;
  final int stockQuantity;
  final bool inStock;
  final int? maxQuantityPerOrder;
  final List<ProductImage>? images;

  Product({required this.id, required this.name, required this.slug, this.sku,
    this.description, required this.price, this.discountPrice,
    this.buyQuantity, this.getQuantity, this.unit,
    this.weightQuantity, this.weightUnit,
    this.pricePerUnit, this.discountPricePerUnit, this.pricePerUnitLabel,
    required this.active, required this.featured, this.thumbnailUrl,
    this.categoryName, this.categoryId, this.brandName,
    required this.stockQuantity, required this.inStock, this.maxQuantityPerOrder, this.images});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'], name: json['name'], slug: json['slug'] ?? '',
    sku: json['sku'], description: json['description'],
    price: (json['price'] as num).toDouble(),
    discountPrice: json['discountPrice'] != null ? (json['discountPrice'] as num).toDouble() : null,
    buyQuantity: json['buyQuantity'],
    getQuantity: json['getQuantity'],
    unit: json['unit'],
    weightQuantity: json['weightQuantity'] != null ? (json['weightQuantity'] as num).toDouble() : null,
    weightUnit: json['weightUnit'],
    pricePerUnit: json['pricePerUnit'] != null ? (json['pricePerUnit'] as num).toDouble() : null,
    discountPricePerUnit: json['discountPricePerUnit'] != null ? (json['discountPricePerUnit'] as num).toDouble() : null,
    pricePerUnitLabel: json['pricePerUnitLabel'],
    active: json['active'] ?? true, featured: json['featured'] ?? false,
    thumbnailUrl: json['thumbnailUrl'], categoryName: json['categoryName'],
    categoryId: json['categoryId'], brandName: json['brandName'],
    stockQuantity: json['stockQuantity'] ?? 0, inStock: json['inStock'] ?? false,
    maxQuantityPerOrder: json['maxQuantityPerOrder'],
    images: json['images'] != null
        ? (json['images'] as List).map((i) => ProductImage.fromJson(i)).toList()
        : null,
  );

  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  bool get hasOffer => buyQuantity != null && getQuantity != null && buyQuantity! >= 1 && getQuantity! >= 1;
  String get offerLabel => '${buyQuantity}+${getQuantity}';
  bool get isWeighed => unit == 'WEIGHED' && weightQuantity != null && weightUnit != null;

  /// e.g. "397gr" for the product label
  String? get weightLabel {
    if (!isWeighed) return null;
    final qty = weightQuantity!;
    final qtyStr = qty == qty.roundToDouble() ? qty.round().toString() : qty.toStringAsFixed(1);
    return '$qtyStr${weightUnit!}';
  }

  /// Builds the per-unit price text for display.
  /// e.g. "397gr · €4.81 from €5.67/kg" or "€3.00 from €5.00/kg" or "€5.00/kg"
  String? get pricePerUnitText {
    if (pricePerUnit == null) return null;
    final label = pricePerUnitLabel ?? '';
    final prefix = isWeighed && weightLabel != null ? '${weightLabel!} · ' : '';

    if (hasOffer) {
      // For offers: just show the original price per unit
      return '$prefix€${pricePerUnit!.toStringAsFixed(2)}$label';
    }
    if (hasDiscount && discountPricePerUnit != null) {
      return '$prefix€${discountPricePerUnit!.toStringAsFixed(2)} from €${pricePerUnit!.toStringAsFixed(2)}$label';
    }
    return '$prefix€${pricePerUnit!.toStringAsFixed(2)}$label';
  }

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
  final int paidQuantity;
  final int freeQuantity;
  final double subtotal;
  final int stockQuantity;
  final int? buyQuantity;
  final int? getQuantity;
  final String? unit;
  final double? weightQuantity;
  final String? weightUnit;
  final int? maxQuantityPerOrder;

  CartItem({required this.id, required this.productId, required this.productName,
    this.productThumbnail, required this.originalPrice, required this.unitPrice,
    required this.quantity, required this.paidQuantity, required this.freeQuantity,
    required this.subtotal, required this.stockQuantity,
    this.buyQuantity, this.getQuantity,
    this.unit, this.weightQuantity, this.weightUnit, this.maxQuantityPerOrder});

  bool get hasDiscount => unitPrice < originalPrice;
  bool get hasOffer => buyQuantity != null && getQuantity != null && buyQuantity! >= 1 && getQuantity! >= 1;
  String get offerLabel => '${buyQuantity}+${getQuantity}';
  bool get isWeighed => unit == 'WEIGHED' && weightQuantity != null && weightUnit != null;

  /// Returns e.g. "500gr" (quantity × weightQuantity + weightUnit) for weighed items
  String? get totalWeightLabel {
    if (!isWeighed) return null;
    final total = quantity * weightQuantity!;
    final totalStr = total == total.roundToDouble() ? total.round().toString() : total.toStringAsFixed(1);
    return '$totalStr${weightUnit!}';
  }

  /// Returns e.g. "100gr" for a single unit weight label
  String? get singleWeightLabel {
    if (!isWeighed) return null;
    final qty = weightQuantity!;
    final qtyStr = qty == qty.roundToDouble() ? qty.round().toString() : qty.toStringAsFixed(1);
    return '$qtyStr${weightUnit!}';
  }

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
    paidQuantity: json['paidQuantity'] ?? json['quantity'],
    freeQuantity: json['freeQuantity'] ?? 0,
    subtotal: (json['subtotal'] as num).toDouble(),
    stockQuantity: json['stockQuantity'] ?? 0,
    buyQuantity: json['buyQuantity'],
    getQuantity: json['getQuantity'],
    unit: json['unit'],
    weightQuantity: json['weightQuantity'] != null ? (json['weightQuantity'] as num).toDouble() : null,
    weightUnit: json['weightUnit'],
    maxQuantityPerOrder: json['maxQuantityPerOrder'],
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
  final String? unit;
  final double? weightQuantity;
  final String? weightUnit;

  OrderItem({required this.id, required this.productId, required this.productName,
    required this.unitPrice, required this.quantity, required this.subtotal,
    this.unit, this.weightQuantity, this.weightUnit});

  bool get isWeighed => unit == 'WEIGHED' && weightQuantity != null && weightUnit != null;

  /// Returns e.g. "500gr" for weighed items
  String? get totalWeightLabel {
    if (!isWeighed) return null;
    final total = quantity * weightQuantity!;
    final totalStr = total == total.roundToDouble() ? total.round().toString() : total.toStringAsFixed(1);
    return '$totalStr${weightUnit!}';
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'], productId: json['productId'],
    productName: json['productName'],
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'],
    subtotal: (json['subtotal'] as num).toDouble(),
    unit: json['unit'],
    weightQuantity: json['weightQuantity'] != null ? (json['weightQuantity'] as num).toDouble() : null,
    weightUnit: json['weightUnit'],
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
  final String? deliveryTimeSlot;
  final String? deliveryMethod;
  final double? expressDeliveryFee;
  final double? plasticBagFee;
  final List<OrderItem> items;
  final String? createdAt;

  Order({required this.id, required this.orderNumber, required this.status,
    required this.totalAmount, required this.shippingAddress,
    this.contactPhone, this.notes, this.deliveryTimeSlot,
    this.deliveryMethod, this.expressDeliveryFee, this.plasticBagFee,
    required this.items, this.createdAt});

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'], orderNumber: json['orderNumber'], status: json['status'],
    totalAmount: (json['totalAmount'] as num).toDouble(),
    shippingAddress: json['shippingAddress'], contactPhone: json['contactPhone'],
    notes: json['notes'],
    deliveryTimeSlot: json['deliveryTimeSlot'],
    deliveryMethod: json['deliveryMethod'],
    expressDeliveryFee: json['expressDeliveryFee'] != null ? (json['expressDeliveryFee'] as num).toDouble() : null,
    plasticBagFee: json['plasticBagFee'] != null ? (json['plasticBagFee'] as num).toDouble() : null,
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
  final double? latitude;
  final double? longitude;

  Address({required this.id, required this.label, required this.addressLine,
    this.city, this.postalCode, this.country, required this.isDefault,
    this.latitude, this.longitude});

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'], label: json['label'], addressLine: json['addressLine'],
    city: json['city'], postalCode: json['postalCode'], country: json['country'],
    isDefault: json['isDefault'] ?? json['default'] ?? false,
    latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
    longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
  );
}

class Banner {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String? linkType;
  final String? contentBody;
  final List<Product>? products;

  Banner({required this.id, required this.title, this.subtitle,
    required this.imageUrl, this.linkUrl, this.linkType, this.contentBody,
    this.products});

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
    id: json['id'], title: json['title'], subtitle: json['subtitle'],
    imageUrl: json['imageUrl'], linkUrl: json['linkUrl'],
    linkType: json['linkType'], contentBody: json['contentBody'],
    products: json['products'] != null
        ? (json['products'] as List).map((p) => Product.fromJson(p)).toList()
        : null,
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

