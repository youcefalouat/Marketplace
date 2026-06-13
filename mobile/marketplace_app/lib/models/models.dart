// Data Models for the Marketplace App

Map<String, dynamic>? _asStringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

double _readDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

// Always returns a UTC DateTime, even if the server omits the 'Z' suffix.
DateTime _readDateTime(dynamic value) {
  if (value is String) {
    final s = value.endsWith('Z') || value.contains('+') ? value : '${value}Z';
    return DateTime.parse(s).toUtc();
  }
  return DateTime.now().toUtc();
}

enum UserRole { user, admin }

class CategoryModel {
  final int id;
  final String name;
  final String arName;
  final String slug;
  final int? parentId;
  final List<CategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    this.arName = '',
    required this.slug,
    this.parentId,
    required this.subCategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] ?? json['subCategories'];
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arName: json['arName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      parentId: json['parentId'] as int?,
      subCategories: childrenJson != null
          ? (childrenJson as List)
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  String nameForLanguage(String languageCode) {
    if (languageCode == 'ar' && arName.trim().isNotEmpty) {
      return arName;
    }

    return name;
  }
}

enum ProductState { neuf, occasion }

enum AnnonceStatus {
  pending,
  approved,
  rejected,
  underReview,
  sold,
  archived,
  deleted,
}

enum AnnonceDeletionStatus { sold, archived, deleted }

extension AnnonceDeletionStatusX on AnnonceDeletionStatus {
  int get apiValue {
    switch (this) {
      case AnnonceDeletionStatus.sold:
        return 4;
      case AnnonceDeletionStatus.archived:
        return 5;
      case AnnonceDeletionStatus.deleted:
        return 6;
    }
  }

  String get label {
    switch (this) {
      case AnnonceDeletionStatus.sold:
        return 'Vendu';
      case AnnonceDeletionStatus.archived:
        return 'Archive / Ne veux plus vendre';
      case AnnonceDeletionStatus.deleted:
        return 'Erreur / Supprime';
    }
  }

  String get successMessage {
    switch (this) {
      case AnnonceDeletionStatus.sold:
        return 'Annonce marquee comme vendue';
      case AnnonceDeletionStatus.archived:
        return 'Annonce archivee';
      case AnnonceDeletionStatus.deleted:
        return 'Annonce supprimee';
    }
  }
}

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
  final String? avatarUrl;
  final bool isVerifiedSeller;

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
    this.avatarUrl,
    this.isVerifiedSeller = false,
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
      avatarUrl: json['avatarUrl'] as String?,
      isVerifiedSeller: json['isVerifiedSeller'] as bool? ?? false,
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
      'avatarUrl': avatarUrl,
      'isVerifiedSeller': isVerifiedSeller,
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

class RegisterResult {
  final String token;
  final User user;
  final bool emailVerificationRequired;

  RegisterResult({
    required this.token,
    required this.user,
    this.emailVerificationRequired = false,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      emailVerificationRequired: json['emailVerificationRequired'] as bool? ?? false,
    );
  }
}

class LegalContent {
  final String titleFr;
  final String contentFr;
  final String titleAr;
  final String contentAr;
  final DateTime updatedAt;

  LegalContent({
    required this.titleFr,
    required this.contentFr,
    required this.titleAr,
    required this.contentAr,
    required this.updatedAt,
  });

  factory LegalContent.fromJson(Map<String, dynamic> json) {
    return LegalContent(
      titleFr: json['titleFr'] as String? ?? '',
      contentFr: json['contentFr'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      contentAr: json['contentAr'] as String? ?? '',
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  String titleForLanguage(String languageCode) =>
      languageCode == 'ar' ? titleAr : titleFr;

  String contentForLanguage(String languageCode) =>
      languageCode == 'ar' ? contentAr : contentFr;
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
  final int? categoryId;
  final String category;
  final String categoryArName;
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
    this.categoryId,
    required this.category,
    this.categoryArName = '',
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
      categoryId: json['categoryId'] as int?,
      category: (json['categoryName'] as String?) ??
          (json['category'] as String?) ??
          '',
      categoryArName: json['categoryArName'] as String? ?? '',
      mainImageUrl: json['mainImageUrl'] as String?,
      mainThumbnailUrl: json['mainThumbnailUrl'] as String?,
      isExchange: json['isExchange'] as bool? ?? false,
      isGoodDeal: json['isGoodDeal'] as bool? ?? false,
      sellerRating: (json['sellerAverageRating'] as num?)?.toDouble(),
      sellerRatingCount: json['sellerRatingCount'] as int?,
      createdAt: _readDateTime(json['createdAt']),
    );
  }
}

class SellerInfo {
  final int id;
  final String name;
  final String? avatarUrl;
  final String phone;
  final String wilayaName;
  final String communeName;
  final double? averageRating;
  final int? ratingCount;
  final bool isVerifiedSeller;

  SellerInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.phone,
    required this.wilayaName,
    required this.communeName,
    this.averageRating,
    this.ratingCount,
    this.isVerifiedSeller = false,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String,
      wilayaName: json['wilayaName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
      isVerifiedSeller: json['isVerifiedSeller'] as bool? ?? false,
    );
  }
}

class AnnonceDetail {
  final int id;
  final String title;
  final String description;
  final double price;
  final int? categoryId;
  final String category;
  final String categoryArName;
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
  final bool reservationEnabled;
  final DateTime createdAt;
  final List<ImageUrlDto> imageUrls;
  final SellerInfo seller;

  AnnonceDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.categoryId,
    required this.category,
    this.categoryArName = '',
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
    this.reservationEnabled = false,
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
      categoryId: json['categoryId'] as int?,
      category: (json['categoryName'] as String?) ??
          (json['category'] as String?) ??
          '',
      categoryArName: json['categoryArName'] as String? ?? '',
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
      reservationEnabled: json['reservationEnabled'] as bool? ?? false,
      createdAt: _readDateTime(json['createdAt']),
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
  final int? categoryId;
  final String category;
  final String categoryArName;
  final String status;
  final String? mainImageUrl;
  final String? mainThumbnailUrl;
  final bool isGoodDeal;
  final bool reservationEnabled;
  final int? moderationThreadId;
  final DateTime createdAt;

  MyAnnonce({
    required this.id,
    required this.title,
    required this.price,
    this.categoryId,
    required this.category,
    this.categoryArName = '',
    required this.status,
    this.mainImageUrl,
    this.mainThumbnailUrl,
    required this.isGoodDeal,
    this.reservationEnabled = false,
    this.moderationThreadId,
    required this.createdAt,
  });

  factory MyAnnonce.fromJson(Map<String, dynamic> json) {
    return MyAnnonce(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      categoryId: json['categoryId'] as int?,
      category: (json['categoryName'] as String?) ??
          (json['category'] as String?) ??
          '',
      categoryArName: json['categoryArName'] as String? ?? '',
      status: json['status'] as String,
      mainImageUrl: json['mainImageUrl'] as String?,
      mainThumbnailUrl: json['mainThumbnailUrl'] as String?,
      isGoodDeal: json['isGoodDeal'] as bool? ?? false,
      reservationEnabled: json['reservationEnabled'] as bool? ?? false,
      moderationThreadId: json['moderationThreadId'] as int?,
      createdAt: _readDateTime(json['createdAt']),
    );
  }
}

class Reservation {
  final int id;
  final int rank;
  final String userName;
  final String phone;
  final DateTime reservationDateTime;
  final DateTime? rendezVousDateTime;

  Reservation({
    required this.id,
    required this.rank,
    required this.userName,
    required this.phone,
    required this.reservationDateTime,
    this.rendezVousDateTime,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: _readInt(json['id']),
      rank: _readInt(json['rank']),
      userName: json['userName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      reservationDateTime: _readDateTime(json['reservationDateTime']),
      rendezVousDateTime: json['rendezVousDateTime'] is String
          ? _readDateTime(json['rendezVousDateTime'])
          : null,
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
      totalPages:
          ((json['totalCount'] as int) + (json['pageSize'] as int) - 1) ~/
              (json['pageSize'] as int),
    );
  }
}

class Conversation {
  final int id;
  final int annonceId;
  final String annonceTitle;
  final String annonceImage;
  final double annoncePrice;
  final String annonceCurrency;
  final int annonceOwnerId;
  final int? annonceCategoryId;
  final String annonceCategoryName;
  final String annonceCategoryArName;
  final String annonceStatus;
  final int interlocutorId;
  final String interlocutorName;
  final bool isInterlocutorOnline;
  final DateTime lastMessageAt;
  final String lastMessageContent;
  final int? lastMessageSenderId;
  final int unreadCount;
  final bool hasUnreadMessages;
  final bool isModeration;

  Conversation({
    required this.id,
    required this.annonceId,
    required this.annonceTitle,
    required this.annonceImage,
    this.annoncePrice = 0,
    this.annonceCurrency = 'DA',
    this.annonceOwnerId = 0,
    this.annonceCategoryId,
    this.annonceCategoryName = '',
    this.annonceCategoryArName = '',
    this.annonceStatus = '',
    required this.interlocutorId,
    required this.interlocutorName,
    this.isInterlocutorOnline = false,
    required this.lastMessageAt,
    required this.lastMessageContent,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.hasUnreadMessages,
    this.isModeration = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final annonce = _asStringKeyMap(json['annonce']);
    final priceValue =
        json['annoncePrice'] ?? json['price'] ?? annonce?['price'];
    final unreadCount = _readInt(json['unreadCount']);

    return Conversation(
      id: _readInt(json['id']),
      annonceId: _readInt(json['annonceId'] ?? annonce?['id']),
      annonceTitle:
          json['annonceTitle'] as String? ?? annonce?['title'] as String? ?? '',
      annonceImage: json['annonceImage'] as String? ??
          json['image'] as String? ??
          annonce?['image'] as String? ??
          '',
      annoncePrice: _readDouble(priceValue),
      annonceCurrency: json['annonceCurrency'] as String? ??
          annonce?['currency'] as String? ??
          'DA',
      annonceOwnerId: _readInt(
        json['annonceOwnerId'] ?? json['ownerId'] ?? annonce?['ownerId'],
      ),
      annonceCategoryId: json['annonceCategoryId'] as int?,
      annonceCategoryName: json['annonceCategoryName'] as String? ?? '',
      annonceCategoryArName: json['annonceCategoryArName'] as String? ?? '',
      annonceStatus: json['annonceStatus'] as String? ?? '',
      interlocutorId: _readInt(json['interlocutorId']),
      interlocutorName: json['interlocutorName'] as String? ?? '',
      isInterlocutorOnline: json['isInterlocutorOnline'] as bool? ?? false,
      lastMessageAt: _readDateTime(json['lastMessageAt']),
      lastMessageContent: json['lastMessageContent'] as String? ?? '',
      lastMessageSenderId: json['lastMessageSenderId'] as int?,
      unreadCount: unreadCount,
      hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? unreadCount > 0,
      isModeration: json['isModeration'] as bool? ?? false,
    );
  }

  bool get isPending => id <= 0;

  Conversation copyWith({
    int? id,
    int? annonceId,
    String? annonceTitle,
    String? annonceImage,
    double? annoncePrice,
    String? annonceCurrency,
    int? annonceOwnerId,
    int? annonceCategoryId,
    String? annonceCategoryName,
    String? annonceCategoryArName,
    String? annonceStatus,
    int? interlocutorId,
    String? interlocutorName,
    bool? isInterlocutorOnline,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    int? lastMessageSenderId,
    int? unreadCount,
    bool? hasUnreadMessages,
    bool? isModeration,
  }) {
    final nextUnreadCount = unreadCount ?? this.unreadCount;
    return Conversation(
      id: id ?? this.id,
      annonceId: annonceId ?? this.annonceId,
      annonceTitle: annonceTitle ?? this.annonceTitle,
      annonceImage: annonceImage ?? this.annonceImage,
      annoncePrice: annoncePrice ?? this.annoncePrice,
      annonceCurrency: annonceCurrency ?? this.annonceCurrency,
      annonceOwnerId: annonceOwnerId ?? this.annonceOwnerId,
      annonceCategoryId: annonceCategoryId ?? this.annonceCategoryId,
      annonceCategoryName: annonceCategoryName ?? this.annonceCategoryName,
      annonceCategoryArName:
          annonceCategoryArName ?? this.annonceCategoryArName,
      annonceStatus: annonceStatus ?? this.annonceStatus,
      interlocutorId: interlocutorId ?? this.interlocutorId,
      interlocutorName: interlocutorName ?? this.interlocutorName,
      isInterlocutorOnline: isInterlocutorOnline ?? this.isInterlocutorOnline,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: nextUnreadCount,
      hasUnreadMessages: hasUnreadMessages ?? nextUnreadCount > 0,
      isModeration: isModeration ?? this.isModeration,
    );
  }
}

enum MessageDeliveryState { sending, sent, failed }

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isMe;
  final String? clientMessageId;
  final MessageDeliveryState deliveryState;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId = 0,
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.readAt,
    required this.isMe,
    this.clientMessageId,
    this.deliveryState = MessageDeliveryState.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _readInt(json['id']),
      conversationId: _readInt(json['conversationId']),
      senderId: _readInt(json['senderId']),
      receiverId: _readInt(json['receiverId']),
      content: json['content'] as String? ?? '',
      sentAt: _readDateTime(json['sentAt']),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] is String
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      isMe: json['isMe'] as bool? ?? false,
      clientMessageId: json['clientMessageId'] as String?,
      deliveryState: MessageDeliveryState.sent,
    );
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    DateTime? readAt,
    bool? isMe,
    String? clientMessageId,
    MessageDeliveryState? deliveryState,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isMe: isMe ?? this.isMe,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      deliveryState: deliveryState ?? this.deliveryState,
    );
  }
}

class UnreadConversationCount {
  final int conversationId;
  final int count;

  const UnreadConversationCount({
    required this.conversationId,
    required this.count,
  });

  factory UnreadConversationCount.fromJson(Map<String, dynamic> json) {
    return UnreadConversationCount(
      conversationId: _readInt(json['conversationId']),
      count: _readInt(json['count']),
    );
  }
}

class UnreadSummary {
  final int totalUnread;
  final List<UnreadConversationCount> conversations;

  const UnreadSummary({
    required this.totalUnread,
    required this.conversations,
  });

  factory UnreadSummary.fromJson(Map<String, dynamic> json) {
    return UnreadSummary(
      totalUnread: _readInt(json['totalUnread']),
      conversations: (json['conversations'] as List<dynamic>? ?? [])
          .map((item) =>
              UnreadConversationCount.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<int, int> get perConversation => {
        for (final item in conversations) item.conversationId: item.count,
      };
}

class MessageReadReceipt {
  final int conversationId;
  final int readerId;
  final DateTime readAt;
  final List<int> messageIds;

  const MessageReadReceipt({
    required this.conversationId,
    required this.readerId,
    required this.readAt,
    required this.messageIds,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      conversationId: _readInt(json['conversationId']),
      readerId: _readInt(json['readerId']),
      readAt: _readDateTime(json['readAt']),
      messageIds: (json['messageIds'] as List<dynamic>? ?? [])
          .map((item) => _readInt(item))
          .toList(),
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
      createdAt: _readDateTime(json['createdAt']),
      lastMessageAt: _readDateTime(json['lastMessageAt']),
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
      sentAt: _readDateTime(json['sentAt']),
      isFromAdmin: json['isFromAdmin'] as bool? ?? false,
      isMe: json['isMe'] as bool? ?? false,
    );
  }
}

class ReservationCreatedResult {
  final int rank;
  final String message;

  ReservationCreatedResult({required this.rank, required this.message});

  factory ReservationCreatedResult.fromJson(Map<String, dynamic> json) {
    return ReservationCreatedResult(
      rank: json['rank'] as int,
      message: json['message'] as String? ?? '',
    );
  }
}
