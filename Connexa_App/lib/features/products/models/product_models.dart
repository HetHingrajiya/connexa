/// Models representing Products, Inquiries, Business Statistics, and Recommended Companies.
class Product {
  const Product({
    required this.id,
    required this.memberId,
    required this.name,
    required this.description,
    required this.category,
    this.subCategory,
    this.tags = const <String>[],
    this.imageUrl,
    this.specifications = const <String, String>{},
    this.viewCount = 0,
    this.inquiryCount = 0,
    this.isActive = true,
    required this.createdAtUtc,
    this.updatedAtUtc,
    this.companyName,
    this.ownerName,
    this.location,
    this.businessType,
    this.isOwner = false,
    this.additionalImages = const <String>[],
    this.industryId,
    this.industryName,
    this.price,
    this.moq,
    this.isOwnerVerified = false,
    this.ownerVerificationStatus = 'NotSubmitted',
  });

  final int id;
  final int memberId;
  final String name;
  final String description;
  final String category;
  final String? subCategory;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, String> specifications;
  final int viewCount;
  final int inquiryCount;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final String? companyName;
  final String? ownerName;
  final String? location;
  final String? businessType;
  final bool isOwner;
  final List<String> additionalImages;
  final int? industryId;
  final String? industryName;
  final String? price;
  final String? moq;
  final bool isOwnerVerified;
  final String ownerVerificationStatus;

  /// Display price string with fallback to specifications.
  String get displayPrice {
    if (price != null && price!.trim().isNotEmpty) return price!.trim();
    if (specifications.containsKey('Price')) return specifications['Price']!.trim();
    if (specifications.containsKey('Price / Unit')) return specifications['Price / Unit']!.trim();
    return '';
  }

  /// Returns all available product image URLs for swipeable gallery.
  List<String> get allImages {
    final List<String> list = <String>[];
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final List<String> parts = imageUrl!.split(RegExp(r'[,;]'));
      for (final String part in parts) {
        final String trimmed = part.trim();
        if (trimmed.isNotEmpty && !list.contains(trimmed)) {
          list.add(trimmed);
        }
      }
    }
    for (final String img in additionalImages) {
      final String trimmed = img.trim();
      if (trimmed.isNotEmpty && !list.contains(trimmed)) {
        list.add(trimmed);
      }
    }
    return list;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subCategory: json['subCategory']?.toString(),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      imageUrl: json['imageUrl']?.toString(),
      specifications:
          (json['specifications'] as Map<String, dynamic>?)?.map(
            (String k, dynamic v) => MapEntry<String, String>(k, v.toString()),
          ) ??
          const <String, String>{},
      viewCount: json['viewCount'] as int? ?? 0,
      inquiryCount: json['inquiryCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'].toString())
          : null,
      companyName: json['companyName']?.toString(),
      ownerName: json['ownerName']?.toString(),
      location: json['location']?.toString(),
      businessType: json['businessType']?.toString(),
      isOwner: json['isOwner'] as bool? ?? false,
      additionalImages:
          (json['additionalImages'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      industryId: (json['industryId'] as num?)?.toInt(),
      industryName: json['industryName']?.toString(),
      price: json['price']?.toString(),
      moq: json['moq']?.toString(),
      isOwnerVerified: json['isOwnerVerified'] == true ||
          json['ownerVerificationStatus']?.toString().toLowerCase() ==
              'approved',
      ownerVerificationStatus:
          json['ownerVerificationStatus']?.toString() ?? 'NotSubmitted',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'memberId': memberId,
      'name': name,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'tags': tags,
      'imageUrl': imageUrl,
      'specifications': specifications,
      'viewCount': viewCount,
      'inquiryCount': inquiryCount,
      'isActive': isActive,
      'createdAtUtc': createdAtUtc.toIso8601String(),
      'updatedAtUtc': updatedAtUtc?.toIso8601String(),
      'companyName': companyName,
      'ownerName': ownerName,
      'location': location,
      'businessType': businessType,
      'isOwner': isOwner,
      'additionalImages': additionalImages,
      'industryId': industryId,
      'industryName': industryName,
      'price': price,
      'moq': moq,
      'isOwnerVerified': isOwnerVerified,
      'ownerVerificationStatus': ownerVerificationStatus,
    };
  }

  Product copyWith({
    int? id,
    int? memberId,
    String? name,
    String? description,
    String? category,
    String? subCategory,
    List<String>? tags,
    String? imageUrl,
    Map<String, String>? specifications,
    int? viewCount,
    int? inquiryCount,
    bool? isActive,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    String? companyName,
    String? ownerName,
    String? location,
    String? businessType,
    bool? isOwner,
    List<String>? additionalImages,
    int? industryId,
    String? industryName,
    String? price,
    String? moq,
    bool? isOwnerVerified,
    String? ownerVerificationStatus,
  }) {
    return Product(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      specifications: specifications ?? this.specifications,
      viewCount: viewCount ?? this.viewCount,
      inquiryCount: inquiryCount ?? this.inquiryCount,
      isActive: isActive ?? this.isActive,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      companyName: companyName ?? this.companyName,
      ownerName: ownerName ?? this.ownerName,
      location: location ?? this.location,
      businessType: businessType ?? this.businessType,
      isOwner: isOwner ?? this.isOwner,
      additionalImages: additionalImages ?? this.additionalImages,
      industryId: industryId ?? this.industryId,
      industryName: industryName ?? this.industryName,
      price: price ?? this.price,
      moq: moq ?? this.moq,
      isOwnerVerified: isOwnerVerified ?? this.isOwnerVerified,
      ownerVerificationStatus:
          ownerVerificationStatus ?? this.ownerVerificationStatus,
    );
  }
}

/// Paginated product catalog response payload.
class ProductCatalogResponse {
  const ProductCatalogResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<Product> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory ProductCatalogResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['items'] as List<dynamic>?;
    final List<Product> items = rawItems != null
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(Product.fromJson)
            .toList()
        : <Product>[];

    return ProductCatalogResponse(
      items: items,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 12,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Filter criteria for querying the network-wide product discovery catalog.
class ProductFilter {
  const ProductFilter({
    this.search,
    this.industryId,
    this.category,
    this.subCategory,
    this.sortBy = 'newest',
    this.memberId,
    this.verifiedOnly,
    this.page = 1,
    this.pageSize = 12,
  });

  final String? search;
  final int? industryId;
  final String? category;
  final String? subCategory;
  final String sortBy;
  final int? memberId;
  final bool? verifiedOnly;
  final int page;
  final int pageSize;

  ProductFilter copyWith({
    String? search,
    int? industryId,
    bool clearIndustry = false,
    String? category,
    bool clearCategory = false,
    String? subCategory,
    bool clearSubCategory = false,
    String? sortBy,
    int? memberId,
    bool? verifiedOnly,
    bool clearVerifiedOnly = false,
    int? page,
    int? pageSize,
  }) {
    return ProductFilter(
      search: search ?? this.search,
      industryId: clearIndustry ? null : (industryId ?? this.industryId),
      category: clearCategory ? null : (category ?? this.category),
      subCategory: clearSubCategory ? null : (subCategory ?? this.subCategory),
      sortBy: sortBy ?? this.sortBy,
      memberId: memberId ?? this.memberId,
      verifiedOnly:
          clearVerifiedOnly ? null : (verifiedOnly ?? this.verifiedOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return <String, dynamic>{
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (industryId != null && industryId! > 0) 'industryId': industryId,
      if (category != null && category!.trim().isNotEmpty && category != 'All')
        'category': category!.trim(),
      if (subCategory != null &&
          subCategory!.trim().isNotEmpty &&
          subCategory != 'All')
        'subCategory': subCategory!.trim(),
      if (sortBy.isNotEmpty && sortBy != 'newest') 'sortBy': sortBy,
      if (memberId != null && memberId! > 0) 'memberId': memberId,
      if (verifiedOnly == true) 'verifiedOnly': true,
      'page': page,
      'pageSize': pageSize,
    };
  }
}


class CreateProductRequest {
  const CreateProductRequest({
    required this.name,
    required this.description,
    required this.category,
    this.subCategory,
    this.tags = const <String>[],
    this.imageUrl,
    this.specifications = const <String, String>{},
    this.industryId,
  });

  final String name;
  final String description;
  final String category;
  final String? subCategory;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, String> specifications;
  final int? industryId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'category': category,
      if (subCategory != null && subCategory!.isNotEmpty)
        'subCategory': subCategory,
      if (tags.isNotEmpty) 'tags': tags,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (specifications.isNotEmpty) 'specifications': specifications,
      if (industryId != null && industryId! > 0) 'industryId': industryId,
    };
  }
}

class UpdateProductRequest {
  const UpdateProductRequest({
    required this.name,
    required this.description,
    required this.category,
    this.subCategory,
    this.tags = const <String>[],
    this.imageUrl,
    this.specifications = const <String, String>{},
    this.industryId,
  });

  final String name;
  final String description;
  final String category;
  final String? subCategory;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, String> specifications;
  final int? industryId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      'tags': tags,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'specifications': specifications,
      if (industryId != null && industryId! > 0) 'industryId': industryId,
    };
  }
}


class ProductInquiry {
  const ProductInquiry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.senderMemberId,
    required this.senderName,
    required this.senderCompanyName,
    required this.recipientMemberId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAtUtc,
    this.recipientCompanyName,
    this.quantityRequirement,
    this.contactPhone,
    this.contactEmail,
    this.respondedAtUtc,
    this.responseMessage,
    this.productThumbnailUrl,
  });

  final int id;
  final int productId;
  final String productName;
  final int senderMemberId;
  final String senderName;
  final String senderCompanyName;
  final int recipientMemberId;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAtUtc;
  final String? recipientCompanyName;
  final String? quantityRequirement;
  final String? contactPhone;
  final String? contactEmail;
  final DateTime? respondedAtUtc;
  final String? responseMessage;
  final String? productThumbnailUrl;

  ProductInquiry copyWith({
    int? id,
    int? productId,
    String? productName,
    int? senderMemberId,
    String? senderName,
    String? senderCompanyName,
    int? recipientMemberId,
    String? subject,
    String? message,
    String? status,
    DateTime? createdAtUtc,
    String? recipientCompanyName,
    String? quantityRequirement,
    String? contactPhone,
    String? contactEmail,
    DateTime? respondedAtUtc,
    String? responseMessage,
    String? productThumbnailUrl,
  }) {
    return ProductInquiry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      senderMemberId: senderMemberId ?? this.senderMemberId,
      senderName: senderName ?? this.senderName,
      senderCompanyName: senderCompanyName ?? this.senderCompanyName,
      recipientMemberId: recipientMemberId ?? this.recipientMemberId,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      recipientCompanyName: recipientCompanyName ?? this.recipientCompanyName,
      quantityRequirement: quantityRequirement ?? this.quantityRequirement,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      respondedAtUtc: respondedAtUtc ?? this.respondedAtUtc,
      responseMessage: responseMessage ?? this.responseMessage,
      productThumbnailUrl: productThumbnailUrl ?? this.productThumbnailUrl,
    );
  }

  factory ProductInquiry.fromJson(Map<String, dynamic> json) {
    return ProductInquiry(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? '',
      senderMemberId: json['senderMemberId'] as int? ?? 0,
      senderName: json['senderName']?.toString() ?? '',
      senderCompanyName: json['senderCompanyName']?.toString() ?? '',
      recipientMemberId: json['recipientMemberId'] as int? ?? 0,
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      recipientCompanyName: json['recipientCompanyName']?.toString(),
      quantityRequirement: json['quantityRequirement']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      respondedAtUtc: json['respondedAtUtc'] != null
          ? DateTime.tryParse(json['respondedAtUtc'].toString())
          : null,
      responseMessage: json['responseMessage']?.toString(),
      productThumbnailUrl: json['productThumbnailUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'productName': productName,
      'senderMemberId': senderMemberId,
      'senderName': senderName,
      'senderCompanyName': senderCompanyName,
      'recipientMemberId': recipientMemberId,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAtUtc': createdAtUtc.toIso8601String(),
      if (recipientCompanyName != null)
        'recipientCompanyName': recipientCompanyName,
      if (quantityRequirement != null)
        'quantityRequirement': quantityRequirement,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (respondedAtUtc != null)
        'respondedAtUtc': respondedAtUtc!.toIso8601String(),
      if (responseMessage != null) 'responseMessage': responseMessage,
      if (productThumbnailUrl != null)
        'productThumbnailUrl': productThumbnailUrl,
    };
  }
}

class RespondToInquiryRequest {
  const RespondToInquiryRequest({required this.responseMessage});

  final String responseMessage;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'responseMessage': responseMessage.trim()};
  }
}

class CreateProductInquiryRequest {
  const CreateProductInquiryRequest({
    required this.subject,
    required this.message,
    this.quantityRequirement,
    this.contactPhone,
    this.contactEmail,
  });

  final String subject;
  final String message;
  final String? quantityRequirement;
  final String? contactPhone;
  final String? contactEmail;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subject': subject,
      'message': message,
      if (quantityRequirement != null && quantityRequirement!.trim().isNotEmpty)
        'quantityRequirement': quantityRequirement!.trim(),
      if (contactPhone != null && contactPhone!.trim().isNotEmpty)
        'contactPhone': contactPhone!.trim(),
      if (contactEmail != null && contactEmail!.trim().isNotEmpty)
        'contactEmail': contactEmail!.trim(),
    };
  }
}

class DashboardStats {
  const DashboardStats({
    this.myProductsCount = 0,
    this.companyViewsCount = 0,
    this.productViewsCount = 0,
    this.connectionRequestsCount = 0,
    this.unreadNotificationsCount = 0,
    this.inquiriesCount = 0,
  });

  final int myProductsCount;
  final int companyViewsCount;
  final int productViewsCount;
  final int connectionRequestsCount;
  final int unreadNotificationsCount;
  final int inquiriesCount;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      myProductsCount: json['myProductsCount'] as int? ?? 0,
      companyViewsCount: json['companyViewsCount'] as int? ?? 0,
      productViewsCount: json['productViewsCount'] as int? ?? 0,
      connectionRequestsCount: json['connectionRequestsCount'] as int? ?? 0,
      unreadNotificationsCount: json['unreadNotificationsCount'] as int? ?? 0,
      inquiriesCount: json['inquiriesCount'] as int? ?? 0,
    );
  }
}

class RecommendedCompany {
  const RecommendedCompany({
    required this.memberId,
    required this.companyName,
    required this.contactPersonName,
    required this.businessType,
    required this.location,
    required this.industryId,
    required this.industryName,
    required this.categoryName,
    this.businessCapabilities = const <String>[],
    this.productCount = 0,
    this.productPreviews = const <String>[],
    this.connectionStatus = 'Connect',
  });

  final int memberId;
  final String companyName;
  final String contactPersonName;
  final String businessType;
  final String location;
  final int industryId;
  final String industryName;
  final String categoryName;
  final List<String> businessCapabilities;
  final int productCount;
  final List<String> productPreviews;
  final String
  connectionStatus; // Connect, Request Sent, Connected, Respond to Request

  factory RecommendedCompany.fromJson(Map<String, dynamic> json) {
    return RecommendedCompany(
      memberId: json['memberId'] as int? ?? 0,
      companyName: json['companyName']?.toString() ?? '',
      contactPersonName: json['contactPersonName']?.toString() ?? '',
      businessType: json['businessType']?.toString() ?? 'Company',
      location: json['location']?.toString() ?? '',
      industryId: json['industryId'] as int? ?? 0,
      industryName: json['industryName']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      businessCapabilities:
          (json['businessCapabilities'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      productCount: json['productCount'] as int? ?? 0,
      productPreviews:
          (json['productPreviews'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      connectionStatus: json['connectionStatus']?.toString() ?? 'Connect',
    );
  }

  RecommendedCompany copyWith({String? connectionStatus}) {
    return RecommendedCompany(
      memberId: memberId,
      companyName: companyName,
      contactPersonName: contactPersonName,
      businessType: businessType,
      location: location,
      industryId: industryId,
      industryName: industryName,
      categoryName: categoryName,
      businessCapabilities: businessCapabilities,
      productCount: productCount,
      productPreviews: productPreviews,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}
