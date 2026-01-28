// Data Models for the Marketplace App

enum UserRole { user, admin }

enum Category { electromenager, meubles, literie, decoration }

enum ProductState { neuf, occasion }

enum AnnonceStatus { pending, approved, rejected }

class User {
  final int id;
  final String email;
  final String name;
  final String phone;
  final String city;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.city,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'city': city,
      'role': role,
    };
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AnnonceListItem {
  final int id;
  final String title;
  final double price;
  final String city;
  final String category;
  final String? mainImageUrl;
  final DateTime createdAt;

  AnnonceListItem({
    required this.id,
    required this.title,
    required this.price,
    required this.city,
    required this.category,
    this.mainImageUrl,
    required this.createdAt,
  });

  factory AnnonceListItem.fromJson(Map<String, dynamic> json) {
    return AnnonceListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      city: json['city'] as String,
      category: json['category'] as String,
      mainImageUrl: json['mainImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SellerInfo {
  final String name;
  final String phone;
  final String city;

  SellerInfo({
    required this.name,
    required this.phone,
    required this.city,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      name: json['name'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
    );
  }
}

class AnnonceDetail {
  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String state;
  final String phone;
  final String city;
  final String status;
  final DateTime createdAt;
  final List<String> imageUrls;
  final SellerInfo seller;

  AnnonceDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.state,
    required this.phone,
    required this.city,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
    required this.seller,
  });

  factory AnnonceDetail.fromJson(Map<String, dynamic> json) {
    return AnnonceDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      state: json['state'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>).cast<String>(),
      seller: SellerInfo.fromJson(json['seller'] as Map<String, dynamic>),
    );
  }
}

class MyAnnonce {
  final int id;
  final String title;
  final double price;
  final String category;
  final String status;
  final String? mainImageUrl;
  final DateTime createdAt;

  MyAnnonce({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.status,
    this.mainImageUrl,
    required this.createdAt,
  });

  factory MyAnnonce.fromJson(Map<String, dynamic> json) {
    return MyAnnonce(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      status: json['status'] as String,
      mainImageUrl: json['mainImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}
