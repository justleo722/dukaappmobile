class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final String? roleId; // from JWT payload: role_id
  final User? user;
  final Shop? shop;
  final List<Shop>? shops;

  const AuthResult({
    required this.success,
    this.message,
    this.token,
    this.roleId,
    this.user,
    this.shop,
    this.shops,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['result'];
    final userJson = data is Map<String, dynamic> ? data['user'] ?? data['session'] : null;
    final shopJson = data is Map<String, dynamic> ? data['shop'] ?? data['active_shop'] : null;
    final shopsRaw = data is Map<String, dynamic> ? data['shops'] : null;

    return AuthResult(
      success: json['status'] == 'success' || json['status'] == 'true',
      message: json['message'] as String?,
      token: (data is Map<String, dynamic> ? (data['token'] ?? data['access_token'] ?? data['jwt']) : null) as String?,
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
      shop: shopJson is Map<String, dynamic> ? Shop.fromJson(shopJson) : null,
      shops: shopsRaw is List
          ? shopsRaw.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }

  factory AuthResult.success({
    String? token,
    User? user,
    Shop? shop,
    List<Shop>? shops,
    String? message,
  }) {
    return AuthResult(
      success: true,
      token: token,
      user: user,
      shop: shop,
      shops: shops,
      message: message,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}

class User {
  final dynamic id;
  final String? username;
  final String? email;
  final String? phone;
  final String? country;
  final String? region;
  final String? iso;
  final String? role;
  final String? avatar;

  const User({
    this.id,
    this.username,
    this.email,
    this.phone,
    this.country,
    this.region,
    this.iso,
    this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'],
      username: json['username'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      region: json['region'] as String?,
      iso: json['iso'] as String?,
      role: json['role'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'country': country,
      'region': region,
      'iso': iso,
      'role': role,
      'avatar': avatar,
    };
  }
}

class Shop {
  final dynamic id;
  final String? shopName;
  final String? shopType;
  final dynamic lobId;
  final String? lobName;
  final bool? isActive;

  const Shop({
    this.id,
    this.shopName,
    this.shopType,
    this.lobId,
    this.lobName,
    this.isActive,
  });

  /// Alias — some API responses use shop_id, some use id.
  dynamic get shopId => id;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? json['shop_id'],
      shopName: json['shop_name'] as String?,
      shopType: json['shop_type'] as String?,
      lobId: json['lob_id'],
      lobName: json['lob_name'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_name': shopName,
      'shop_type': shopType,
      'lob_id': lobId,
      'lob_name': lobName,
      'is_active': isActive,
    };
  }
}

class BusinessCategory {
  final dynamic id;
  final String? name;
  final String? description;

  const BusinessCategory({
    this.id,
    this.name,
    this.description,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] ?? json['lob_id'],
      name: json['name'] ?? json['lob_name'] ?? json['category_name'] as String?,
      description: json['description'] as String?,
    );
  }
}

class AuthConstants {
  final List<BusinessCategory> businessCategories;
  final List<Map<String, dynamic>> shopTypes;
  final List<Map<String, dynamic>> regions;
  final List<Map<String, dynamic>> countries;

  const AuthConstants({
    this.businessCategories = const [],
    this.shopTypes = const [],
    this.regions = const [],
    this.countries = const [],
  });

  factory AuthConstants.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    final categoriesRaw = data is Map<String, dynamic> ? (data['business_categories'] ?? data['categories'] ?? data['lobs']) : null;
    final shopTypesRaw = data is Map<String, dynamic> ? data['shop_types'] : null;
    final regionsRaw = data is Map<String, dynamic> ? data['regions'] : null;
    final countriesRaw = data is Map<String, dynamic> ? data['countries'] : null;

    return AuthConstants(
      businessCategories: categoriesRaw is List
          ? categoriesRaw.map((e) => BusinessCategory.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      shopTypes: shopTypesRaw is List
          ? shopTypesRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [],
      regions: regionsRaw is List
          ? regionsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [],
      countries: countriesRaw is List
          ? countriesRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [],
    );
  }
}
