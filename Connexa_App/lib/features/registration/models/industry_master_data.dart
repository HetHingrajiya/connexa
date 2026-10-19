import 'package:flutter/foundation.dart';

int _parseInt(dynamic value, String fieldName) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final int? parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  throw FormatException(
    '$fieldName record is missing a valid integer id: $value',
  );
}

int? _tryParseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

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
    final int id = _parseInt(rawId, 'Industry');

    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('Industry record is missing a valid name');
    }
    return Industry(
      id: id,
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final int id;
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
    final int id = _parseInt(rawId, 'BusinessGroup');

    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException(
        'BusinessGroup record is missing a valid name',
      );
    }
    final dynamic rawIndustryId =
        json['industryId'] ?? json['industry_id'] ?? json['parentId'];
    final int industryId = _tryParseInt(rawIndustryId) ?? 0;

    return BusinessGroup(
      id: id,
      industryId: industryId,
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final int id;
  final int industryId;
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
    final int id = _parseInt(rawId, 'SubGroup');

    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('SubGroup record is missing a valid name');
    }
    final dynamic rawGroupId =
        json['businessGroupId'] ??
        json['business_group_id'] ??
        json['groupId'] ??
        json['parentId'];
    final int businessGroupId = _tryParseInt(rawGroupId) ?? 0;

    return SubGroup(
      id: id,
      businessGroupId: businessGroupId,
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final int id;
  final int businessGroupId;
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
    final int id = _parseInt(rawId, 'Category');

    final dynamic rawName = json['name'] ?? json['label'] ?? json['title'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('Category record is missing a valid name');
    }
    final dynamic rawSubGroupId =
        json['subGroupId'] ?? json['sub_group_id'] ?? json['parentId'];
    final int subGroupId = _tryParseInt(rawSubGroupId) ?? 0;

    return Category(
      id: id,
      subGroupId: subGroupId,
      name: rawName.toString().trim(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final int id;
  final int subGroupId;
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

  factory IndustrySelection.fromJson(Map<String, dynamic> json) {
    return IndustrySelection(
      industryId: _tryParseInt(json['industryId']) ?? 0,
      industryName: json['industryName']?.toString() ?? '',
      businessGroupId: _tryParseInt(json['businessGroupId']) ?? 0,
      businessGroupName: json['businessGroupName']?.toString() ?? '',
      subGroupId: _tryParseInt(json['subGroupId']) ?? 0,
      subGroupName: json['subGroupName']?.toString() ?? '',
      categoryId: _tryParseInt(json['categoryId']) ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
    );
  }

  final int industryId;
  final String industryName;
  final int businessGroupId;
  final String businessGroupName;
  final int subGroupId;
  final String subGroupName;
  final int categoryId;
  final String categoryName;

  /// Returns true only if all 4 tiers of the hierarchy have valid database integer IDs.
  bool get isComplete =>
      industryId > 0 && businessGroupId > 0 && subGroupId > 0 && categoryId > 0;

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
