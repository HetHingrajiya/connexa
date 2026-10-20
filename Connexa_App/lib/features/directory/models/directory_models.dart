/// Represents a verified business in the Connexa Business Directory.
class BusinessDirectoryItem {
  const BusinessDirectoryItem({
    required this.memberId,
    required this.companyName,
    required this.contactPersonName,
    required this.email,
    required this.phoneNumber,
    required this.businessCapabilities,
    this.businessDescription,
    required this.industryId,
    required this.industryName,
    required this.businessGroupId,
    required this.businessGroupName,
    required this.subGroupId,
    required this.subGroupName,
    required this.categoryId,
    required this.categoryName,
    required this.verifiedMethod,
    required this.memberSinceUtc,
    this.businessType = 'Manufacturer / Company',
    this.location = 'Gujarat, India',
    this.maskedEmail,
    this.maskedPhoneNumber,
    this.connectionStatus = 'Not Connected',
  });

  final int memberId;
  final String companyName;
  final String contactPersonName;
  final String email;
  final String phoneNumber;
  final List<String> businessCapabilities;
  final String? businessDescription;
  final int industryId;
  final String industryName;
  final int businessGroupId;
  final String businessGroupName;
  final int subGroupId;
  final String subGroupName;
  final int categoryId;
  final String categoryName;
  final String verifiedMethod;
  final DateTime memberSinceUtc;
  final String businessType;
  final String? location;
  final String? maskedEmail;
  final String? maskedPhoneNumber;
  final String connectionStatus;

  /// Displayable email respecting privacy policy
  String get displayEmail =>
      maskedEmail ?? (email.isNotEmpty ? email : 'Protected');

  /// Displayable phone number respecting privacy policy
  String get displayPhone =>
      maskedPhoneNumber ?? (phoneNumber.isNotEmpty ? phoneNumber : 'Protected');

  /// Clean displayable location fallback
  String get displayLocation =>
      (location != null && location!.trim().isNotEmpty)
      ? location!.trim()
      : 'Gujarat, India';

  factory BusinessDirectoryItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawCaps =
        json['businessCapabilities'] as List<dynamic>?;
    final List<String> caps = rawCaps != null
        ? rawCaps.map((dynamic c) => c.toString()).toList()
        : <String>[];

    return BusinessDirectoryItem(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      companyName: json['companyName']?.toString() ?? '',
      contactPersonName: json['contactPersonName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      businessCapabilities: caps,
      businessDescription: json['businessDescription']?.toString(),
      industryId: (json['industryId'] as num?)?.toInt() ?? 0,
      industryName: json['industryName']?.toString() ?? '',
      businessGroupId: (json['businessGroupId'] as num?)?.toInt() ?? 0,
      businessGroupName: json['businessGroupName']?.toString() ?? '',
      subGroupId: (json['subGroupId'] as num?)?.toInt() ?? 0,
      subGroupName: json['subGroupName']?.toString() ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      verifiedMethod: json['verifiedMethod']?.toString() ?? 'Email',
      memberSinceUtc:
          DateTime.tryParse(json['memberSinceUtc']?.toString() ?? '') ??
          DateTime.now(),
      businessType:
          json['businessType']?.toString() ?? 'Manufacturer / Company',
      location: json['location']?.toString() ?? 'Gujarat, India',
      maskedEmail: json['maskedEmail']?.toString(),
      maskedPhoneNumber: json['maskedPhoneNumber']?.toString(),
      connectionStatus: json['connectionStatus']?.toString() ?? 'Not Connected',
    );
  }

  BusinessDirectoryItem copyWith({
    int? memberId,
    String? companyName,
    String? contactPersonName,
    String? email,
    String? phoneNumber,
    List<String>? businessCapabilities,
    String? businessDescription,
    int? industryId,
    String? industryName,
    int? businessGroupId,
    String? businessGroupName,
    int? subGroupId,
    String? subGroupName,
    int? categoryId,
    String? categoryName,
    String? verifiedMethod,
    DateTime? memberSinceUtc,
    String? businessType,
    String? location,
    String? maskedEmail,
    String? maskedPhoneNumber,
    String? connectionStatus,
  }) {
    return BusinessDirectoryItem(
      memberId: memberId ?? this.memberId,
      companyName: companyName ?? this.companyName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessCapabilities: businessCapabilities ?? this.businessCapabilities,
      businessDescription: businessDescription ?? this.businessDescription,
      industryId: industryId ?? this.industryId,
      industryName: industryName ?? this.industryName,
      businessGroupId: businessGroupId ?? this.businessGroupId,
      businessGroupName: businessGroupName ?? this.businessGroupName,
      subGroupId: subGroupId ?? this.subGroupId,
      subGroupName: subGroupName ?? this.subGroupName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      verifiedMethod: verifiedMethod ?? this.verifiedMethod,
      memberSinceUtc: memberSinceUtc ?? this.memberSinceUtc,
      businessType: businessType ?? this.businessType,
      location: location ?? this.location,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      maskedPhoneNumber: maskedPhoneNumber ?? this.maskedPhoneNumber,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

/// Paginated directory response payload.
class BusinessDirectoryResponse {
  const BusinessDirectoryResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<BusinessDirectoryItem> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory BusinessDirectoryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['items'] as List<dynamic>?;
    final List<BusinessDirectoryItem> items = rawItems != null
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(BusinessDirectoryItem.fromJson)
              .toList()
        : <BusinessDirectoryItem>[];

    return BusinessDirectoryResponse(
      items: items,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Filter criteria for querying the business directory.
class BusinessDirectoryFilter {
  const BusinessDirectoryFilter({
    this.search,
    this.industryId,
    this.businessGroupId,
    this.subGroupId,
    this.categoryId,
    this.capability,
    this.businessType,
    this.location,
    this.page = 1,
    this.pageSize = 10,
  });

  final String? search;
  final int? industryId;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String? capability;
  final String? businessType;
  final String? location;
  final int page;
  final int pageSize;

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      (industryId != null && industryId! > 0) ||
      (businessGroupId != null && businessGroupId! > 0) ||
      (subGroupId != null && subGroupId! > 0) ||
      (categoryId != null && categoryId! > 0) ||
      (capability != null && capability!.trim().isNotEmpty) ||
      (businessType != null &&
          businessType!.trim().isNotEmpty &&
          businessType != 'All') ||
      (location != null && location!.trim().isNotEmpty);

  BusinessDirectoryFilter copyWith({
    String? search,
    int? industryId,
    int? businessGroupId,
    int? subGroupId,
    int? categoryId,
    String? capability,
    String? businessType,
    String? location,
    int? page,
    int? pageSize,
    bool clearSearch = false,
    bool clearIndustry = false,
    bool clearBusinessGroup = false,
    bool clearSubGroup = false,
    bool clearCategory = false,
    bool clearCapability = false,
    bool clearBusinessType = false,
    bool clearLocation = false,
  }) {
    return BusinessDirectoryFilter(
      search: clearSearch ? null : (search ?? this.search),
      industryId: clearIndustry ? null : (industryId ?? this.industryId),
      businessGroupId: clearBusinessGroup
          ? null
          : (businessGroupId ?? this.businessGroupId),
      subGroupId: clearSubGroup ? null : (subGroupId ?? this.subGroupId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      capability: clearCapability ? null : (capability ?? this.capability),
      businessType: clearBusinessType
          ? null
          : (businessType ?? this.businessType),
      location: clearLocation ? null : (location ?? this.location),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (industryId != null && industryId! > 0) {
      params['industryId'] = industryId;
    }
    if (businessGroupId != null && businessGroupId! > 0) {
      params['businessGroupId'] = businessGroupId;
    }
    if (subGroupId != null && subGroupId! > 0) {
      params['subGroupId'] = subGroupId;
    }
    if (categoryId != null && categoryId! > 0) {
      params['categoryId'] = categoryId;
    }
    if (capability != null && capability!.trim().isNotEmpty) {
      params['capability'] = capability!.trim();
    }
    if (businessType != null &&
        businessType!.trim().isNotEmpty &&
        businessType != 'All') {
      params['businessType'] = businessType!.trim();
    }
    if (location != null && location!.trim().isNotEmpty) {
      params['location'] = location!.trim();
    }
    return params;
  }
}
