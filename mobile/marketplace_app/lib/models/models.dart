// Data Models for the Marketplace App

enum UserRole { user, admin }

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final int? parentId;
  final List<CategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    required this.subCategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentId: json['parentId'] as int?,
      subCategories: json['subCategories'] != null
          ? (json['subCategories'] as List)
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

enum ProductState { neuf, occasion }

enum AnnonceStatus { pending, approved, rejected, underReview }

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
  final String? provider;
  final String? providerId;
  final bool phoneVerified;
  final bool emailVerified;

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
    this.provider,
    this.providerId,
    this.phoneVerified = false,
    this.emailVerified = false,
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
      provider: json['provider'] as String?,
      providerId: json['providerId'] as String?,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
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
      'provider': provider,
      'providerId': providerId,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
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

class ImageUrlDto {
  final String url;
  final String? thumbnailSmall;
  final String? thumbnailMedium;

  ImageUrlDto({
    required this.url,
    this.thumbnailSmall,
    this.thumbnailMedium,
  });

  factory ImageUrlDto.fromJson(Map<String, dynamic> json) {
    return ImageUrlDto(
      url: json['url'] as String,
      thumbnailSmall: json['thumbnailSmall'] as String?,
      thumbnailMedium: json['thumbnailMedium'] as String?,
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
  final String? mainThumbnailUrl;
  final bool isExchange;
  final bool isGoodDeal;
  final double? sellerRating;
  final int? sellerRatingCount;
  final DateTime createdAt;

  AnnonceListItem({
    required this.id,
    required this.title,
    required this.price,
    required this.wilayaName,
    required this.communeName,
    required this.category,
    this.mainImageUrl,
    this.mainThumbnailUrl,
    required this.isExchange,
    required this.isGoodDeal,
    this.sellerRating,
    this.sellerRatingCount,
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
      mainThumbnailUrl: json['mainThumbnailUrl'] as String?,
      isExchange: json['isExchange'] as bool? ?? false,
      isGoodDeal: json['isGoodDeal'] as bool? ?? false,
      sellerRating: (json['sellerAverageRating'] as num?)?.toDouble(),
      sellerRatingCount: json['sellerRatingCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SellerInfo {
  final int id;
  final String name;
  final String phone;
  final String wilayaName;
  final String communeName;
  final double? averageRating;
  final int? ratingCount;

  SellerInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.wilayaName,
    required this.communeName,
    this.averageRating,
    this.ratingCount,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      phone: json['phone'] as String,
      wilayaName: json['wilayaName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
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
  final bool isGoodDeal;
  final DateTime createdAt;
  final List<ImageUrlDto> imageUrls;
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
    required this.isGoodDeal,
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
      isGoodDeal: json['isGoodDeal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>)
          .map((e) => ImageUrlDto.fromJson(e as Map<String, dynamic>))
          .toList(),
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
  final String? mainThumbnailUrl;
  final bool isGoodDeal;
  final int? moderationThreadId;
  final DateTime createdAt;

  MyAnnonce({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.status,
    this.mainImageUrl,
    this.mainThumbnailUrl,
    required this.isGoodDeal,
    this.moderationThreadId,
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
      mainThumbnailUrl: json['mainThumbnailUrl'] as String?,
      isGoodDeal: json['isGoodDeal'] as bool? ?? false,
      moderationThreadId: json['moderationThreadId'] as int?,
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
      totalPages: ((json['totalCount'] as int) + (json['pageSize'] as int) - 1) ~/ (json['pageSize'] as int),
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
  final bool isModeration;

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
    this.isModeration = false,
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
      isModeration: json['isModeration'] as bool? ?? false,
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

class ModerationThread {
  final int id;
  final int annonceId;
  final String annonceTitle;
  final String annonceStatus;
  final int ownerId;
  final String ownerName;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isClosed;
  final List<ModerationMessage> messages;

  ModerationThread({
    required this.id,
    required this.annonceId,
    required this.annonceTitle,
    required this.annonceStatus,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    required this.lastMessageAt,
    required this.isClosed,
    required this.messages,
  });

  factory ModerationThread.fromJson(Map<String, dynamic> json) {
    return ModerationThread(
      id: json['id'] as int,
      annonceId: json['annonceId'] as int,
      annonceTitle: json['annonceTitle'] as String? ?? '',
      annonceStatus: json['annonceStatus'] as String? ?? '',
      ownerId: json['ownerId'] as int,
      ownerName: json['ownerName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      isClosed: json['isClosed'] as bool? ?? false,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((item) =>
              ModerationMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ModerationMessage {
  final int id;
  final int threadId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isFromAdmin;
  final bool isMe;

  ModerationMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    required this.isFromAdmin,
    required this.isMe,
  });

  factory ModerationMessage.fromJson(Map<String, dynamic> json) {
    return ModerationMessage(
      id: json['id'] as int,
      threadId: json['threadId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      sentAt: DateTime.parse(json['sentAt'] as String),
      isFromAdmin: json['isFromAdmin'] as bool? ?? false,
      isMe: json['isMe'] as bool? ?? false,
    );
  }
}
