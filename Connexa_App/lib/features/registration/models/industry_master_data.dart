import 'package:flutter/foundation.dart';

/// Top-level Industry classification item from master data API.
@immutable
class Industry {
  const Industry({
    required this.id,
    required this.name,
    this.code,
    this.description,
  });

  factory Industry.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['_id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw const FormatException('Industry record is missing a valid id');
    }
    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('Industry record is missing a valid name');
    }
    return Industry(
      id: rawId.toString(),
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final String id;
  final String name;
  final String? code;
  final String? description;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Industry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Industry(id: $id, name: $name)';
}

/// Second-tier classification item representing a Business Group under an [Industry].
@immutable
class BusinessGroup {
  const BusinessGroup({
    required this.id,
    required this.industryId,
    required this.name,
    this.code,
    this.description,
  });

  factory BusinessGroup.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['_id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw const FormatException('BusinessGroup record is missing a valid id');
    }
    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException(
        'BusinessGroup record is missing a valid name',
      );
    }
    final dynamic rawIndustryId =
        json['industryId'] ?? json['industry_id'] ?? json['parentId'];

    return BusinessGroup(
      id: rawId.toString(),
      industryId: rawIndustryId?.toString() ?? '',
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final String id;
  final String industryId;
  final String name;
  final String? code;
  final String? description;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'industryId': industryId,
    'name': name,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BusinessGroup(id: $id, name: $name)';
}

/// Third-tier classification item representing a SubGroup under a [BusinessGroup].
@immutable
class SubGroup {
  const SubGroup({
    required this.id,
    required this.businessGroupId,
    required this.name,
    this.code,
    this.description,
  });

  factory SubGroup.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['_id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw const FormatException('SubGroup record is missing a valid id');
    }
    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('SubGroup record is missing a valid name');
    }
    final dynamic rawGroupId =
        json['businessGroupId'] ??
        json['business_group_id'] ??
        json['groupId'] ??
        json['parentId'];

    return SubGroup(
      id: rawId.toString(),
      businessGroupId: rawGroupId?.toString() ?? '',
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final String id;
  final String businessGroupId;
  final String name;
  final String? code;
  final String? description;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'businessGroupId': businessGroupId,
    'name': name,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SubGroup(id: $id, name: $name)';
}

/// Fourth-tier classification item representing a specific Category under a [SubGroup].
@immutable
class Category {
  const Category({
    required this.id,
    required this.subGroupId,
    required this.name,
    this.code,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['_id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw const FormatException('Category record is missing a valid id');
    }
    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('Category record is missing a valid name');
    }
    final dynamic rawSubGroupId =
        json['subGroupId'] ?? json['sub_group_id'] ?? json['parentId'];

    return Category(
      id: rawId.toString(),
      subGroupId: rawSubGroupId?.toString() ?? '',
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final String id;
  final String subGroupId;
  final String name;
  final String? code;
  final String? description;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'subGroupId': subGroupId,
    'name': name,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name)';
}

/// Complete selected hierarchy saved to the registration draft with both IDs and labels.
@immutable
class IndustrySelection {
  const IndustrySelection({
    required this.industryId,
    required this.industryName,
    required this.businessGroupId,
    required this.businessGroupName,
    required this.subGroupId,
    required this.subGroupName,
    required this.categoryId,
    required this.categoryName,
  });

  final String industryId;
  final String industryName;
  final String businessGroupId;
  final String businessGroupName;
  final String subGroupId;
  final String subGroupName;
  final String categoryId;
  final String categoryName;

  /// Returns true only if all 4 tiers of the hierarchy have valid database IDs.
  bool get isComplete =>
      industryId.isNotEmpty &&
      businessGroupId.isNotEmpty &&
      subGroupId.isNotEmpty &&
      categoryId.isNotEmpty;

  /// Formatted hierarchical breadcrumb label.
  String get displayPath =>
      '$industryName > $businessGroupName > $subGroupName > $categoryName';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'industryId': industryId,
    'industryName': industryName,
    'businessGroupId': businessGroupId,
    'businessGroupName': businessGroupName,
    'subGroupId': subGroupId,
    'subGroupName': subGroupName,
    'categoryId': categoryId,
    'categoryName': categoryName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndustrySelection &&
          runtimeType == other.runtimeType &&
          industryId == other.industryId &&
          businessGroupId == other.businessGroupId &&
          subGroupId == other.subGroupId &&
          categoryId == other.categoryId;

  @override
  int get hashCode =>
      Object.hash(industryId, businessGroupId, subGroupId, categoryId);

  @override
  String toString() => 'IndustrySelection($displayPath)';
}
