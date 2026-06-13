class SellerProfile {
  final int id;
  final String name;
  final String? avatarUrl;
  final String communeName;
  final String wilayaName;
  final bool isVerifiedSeller;
  final double? averageRating;
  final int totalReviews;
  final int totalAnnonces;
  final DateTime memberSince;

  const SellerProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.communeName,
    required this.wilayaName,
    required this.isVerifiedSeller,
    this.averageRating,
    required this.totalReviews,
    required this.totalAnnonces,
    required this.memberSince,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      communeName: json['communeName'] as String? ?? '',
      wilayaName: json['wilayaName'] as String? ?? '',
      isVerifiedSeller: json['isVerifiedSeller'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalAnnonces: json['totalAnnonces'] as int? ?? 0,
      memberSince: _parseUtc(json['memberSince']),
    );
  }
}

class SellerReview {
  final int reviewerId;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const SellerReview({
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatarUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory SellerReview.fromJson(Map<String, dynamic> json) {
    return SellerReview(
      reviewerId: json['reviewerId'] as int,
      reviewerName: json['reviewerName'] as String? ?? '',
      reviewerAvatarUrl: json['reviewerAvatarUrl'] as String?,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: _parseUtc(json['createdAt']),
    );
  }
}

class TopVerifiedUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String communeName;
  final String wilayaName;
  final double? averageRating;
  final int totalReviews;
  final int totalAnnonces;
  final bool isVerifiedSeller;

  const TopVerifiedUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.communeName,
    required this.wilayaName,
    this.averageRating,
    required this.totalReviews,
    required this.totalAnnonces,
    required this.isVerifiedSeller,
  });

  factory TopVerifiedUser.fromJson(Map<String, dynamic> json) {
    return TopVerifiedUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      communeName: json['communeName'] as String? ?? '',
      wilayaName: json['wilayaName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalAnnonces: json['totalAnnonces'] as int? ?? 0,
      isVerifiedSeller: json['isVerifiedSeller'] as bool? ?? false,
    );
  }
}

class UserSearchResult {
  final int id;
  final String name;
  final String? avatarUrl;
  final bool isVerifiedSeller;
  final String communeName;
  final String wilayaName;
  final double? averageRating;

  const UserSearchResult({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isVerifiedSeller,
    required this.communeName,
    required this.wilayaName,
    this.averageRating,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerifiedSeller: json['isVerifiedSeller'] as bool? ?? false,
      communeName: json['communeName'] as String? ?? '',
      wilayaName: json['wilayaName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );
  }
}

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String communeName;
  final String wilayaName;
  final double? averageRating;
  final int totalAnnonces;
  final bool isVerifiedSeller;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.communeName,
    required this.wilayaName,
    this.averageRating,
    required this.totalAnnonces,
    required this.isVerifiedSeller,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      communeName: json['communeName'] as String? ?? '',
      wilayaName: json['wilayaName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalAnnonces: json['totalAnnonces'] as int? ?? 0,
      isVerifiedSeller: json['isVerifiedSeller'] as bool? ?? false,
      createdAt: _parseUtc(json['createdAt']),
    );
  }
}

DateTime _parseUtc(dynamic value) {
  if (value is String) {
    final s = value.endsWith('Z') || value.contains('+') ? value : '${value}Z';
    return DateTime.parse(s).toUtc();
  }
  return DateTime.now().toUtc();
}
