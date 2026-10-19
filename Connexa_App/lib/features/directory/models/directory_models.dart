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
    this.page = 1,
    this.pageSize = 10,
  });

  final String? search;
  final int? industryId;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String? capability;
  final int page;
  final int pageSize;

  BusinessDirectoryFilter copyWith({
    String? search,
    int? industryId,
    int? businessGroupId,
    int? subGroupId,
    int? categoryId,
    String? capability,
    int? page,
    int? pageSize,
    bool clearSearch = false,
    bool clearIndustry = false,
    bool clearBusinessGroup = false,
    bool clearSubGroup = false,
    bool clearCategory = false,
    bool clearCapability = false,
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
    return params;
  }
}
