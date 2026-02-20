// Data Models for the Marketplace App

enum UserRole { user, admin }

enum Category { electromenager, meubles, literie, decoration }

enum ProductState { neuf, occasion }

enum AnnonceStatus { pending, approved, rejected }

class Wilaya {
  final int id;
  final String code;
  final String name;
  final String arName;

  Wilaya({
    required this.id,
    required this.code,
    required this.name,
    required this.arName,
  });

  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      arName: json['arName'] as String? ?? '',
    );
  }
}

class Commune {
  final int id;
  final String name;
  final String arName;
  final int wilayaId;

  Commune({
    required this.id,
    required this.name,
    required this.arName,
    required this.wilayaId,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      id: json['id'] as int,
      name: json['name'] as String,
      arName: json['arName'] as String? ?? '',
      wilayaId: json['wilayaId'] as int,
    );
  }
}

class User {
  final int id;
  final String email;
  final String name;
  final String phone;
  final int wilayaId;
  final int communeId;
  final String wilayaName;
  final String communeName;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.wilayaId,
    required this.communeId,
    required this.wilayaName,
    required this.communeName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      wilayaId: json['wilayaId'] as int,
      communeId: json['communeId'] as int,
      wilayaName: json['wilayaName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'wilayaId': wilayaId,
      'communeId': communeId,
      'wilayaName': wilayaName,
      'communeName': communeName,
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
  final String wilayaName;
  final String communeName;
  final String category;
  final String? mainImageUrl;
  final bool isExchange;
  final DateTime createdAt;

  AnnonceListItem({
    required this.id,
    required this.title,
    required this.price,
    required this.wilayaName,
    required this.communeName,
    required this.category,
    this.mainImageUrl,
    required this.isExchange,
    required this.createdAt,
  });

  factory AnnonceListItem.fromJson(Map<String, dynamic> json) {
    return AnnonceListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      wilayaName: json['wilayaName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      category: json['category'] as String,
      mainImageUrl: json['mainImageUrl'] as String?,
      isExchange: json['isExchange'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SellerInfo {
  final String name;
  final String phone;
  final String wilayaName;
  final String communeName;

  SellerInfo({
    required this.name,
    required this.phone,
    required this.wilayaName,
    required this.communeName,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      name: json['name'] as String,
      phone: json['phone'] as String,
      wilayaName: json['wilayaName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
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
  final int wilayaId;
  final int communeId;
  final String wilayaName;
  final String communeName;
  final bool isExchange;
  final bool showPhone;
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
    required this.wilayaId,
    required this.communeId,
    required this.wilayaName,
    required this.communeName,
    required this.isExchange,
    required this.showPhone,
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
      wilayaId: json['wilayaId'] as int,
      communeId: json['communeId'] as int,
      wilayaName: json['wilayaName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      isExchange: json['isExchange'] as bool? ?? false,
      showPhone: json['showPhone'] as bool? ?? true,
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

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: (json['totalCount'] as int) ~/ (json['pageSize'] as int),
    );
  }
}

class Conversation {
  final int id;
  final int annonceId;
  final String annonceTitle;
  final String annonceImage;
  final int interlocutorId;
  final String interlocutorName;
  final DateTime lastMessageAt;
  final String lastMessageContent;
  final bool hasUnreadMessages;

  Conversation({
    required this.id,
    required this.annonceId,
    required this.annonceTitle,
    required this.annonceImage,
    required this.interlocutorId,
    required this.interlocutorName,
    required this.lastMessageAt,
    required this.lastMessageContent,
    required this.hasUnreadMessages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      annonceId: json['annonceId'] as int,
      annonceTitle: json['annonceTitle'] as String? ?? '',
      annonceImage: json['annonceImage'] as String? ?? '',
      interlocutorId: json['interlocutorId'] as int,
      interlocutorName: json['interlocutorName'] as String? ?? '',
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      lastMessageContent: json['lastMessageContent'] as String? ?? '',
      hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    required this.isRead,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      senderId: json['senderId'] as int,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool,
      isMe: json['isMe'] as bool,
    );
  }
}
