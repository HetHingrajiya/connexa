import 'package:flutter/material.dart';
import 'package:connexa/core/theme/theme.dart';

enum ServiceInquiryStatus {
  pending,
  underReview,
  responded,
  accepted,
  declined,
  closed;

  static ServiceInquiryStatus fromInt(int value) {
    switch (value) {
      case 1:
        return ServiceInquiryStatus.pending;
      case 2:
        return ServiceInquiryStatus.underReview;
      case 3:
        return ServiceInquiryStatus.responded;
      case 4:
        return ServiceInquiryStatus.accepted;
      case 5:
        return ServiceInquiryStatus.declined;
      case 6:
        return ServiceInquiryStatus.closed;
      default:
        return ServiceInquiryStatus.pending;
    }
  }

  static ServiceInquiryStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'underreview':
      case 'under_review':
        return ServiceInquiryStatus.underReview;
      case 'responded':
        return ServiceInquiryStatus.responded;
      case 'accepted':
        return ServiceInquiryStatus.accepted;
      case 'declined':
        return ServiceInquiryStatus.declined;
      case 'closed':
        return ServiceInquiryStatus.closed;
      case 'pending':
      default:
        return ServiceInquiryStatus.pending;
    }
  }

  int toInt() {
    switch (this) {
      case ServiceInquiryStatus.pending:
        return 1;
      case ServiceInquiryStatus.underReview:
        return 2;
      case ServiceInquiryStatus.responded:
        return 3;
      case ServiceInquiryStatus.accepted:
        return 4;
      case ServiceInquiryStatus.declined:
        return 5;
      case ServiceInquiryStatus.closed:
        return 6;
    }
  }

  String get label {
    switch (this) {
      case ServiceInquiryStatus.pending:
        return 'Pending';
      case ServiceInquiryStatus.underReview:
        return 'Under Review';
      case ServiceInquiryStatus.responded:
        return 'Responded';
      case ServiceInquiryStatus.accepted:
        return 'Accepted';
      case ServiceInquiryStatus.declined:
        return 'Declined';
      case ServiceInquiryStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case ServiceInquiryStatus.pending:
        return AppColors.warning;
      case ServiceInquiryStatus.underReview:
        return AppColors.primary;
      case ServiceInquiryStatus.responded:
        return AppColors.secondary;
      case ServiceInquiryStatus.accepted:
        return AppColors.success;
      case ServiceInquiryStatus.declined:
      case ServiceInquiryStatus.closed:
        return AppColors.textMuted;
    }
  }
}

class ServiceSummary {
  const ServiceSummary({
    required this.id,
    required this.memberId,
    required this.providerName,
    this.providerCompanyName,
    this.providerCity,
    this.providerState,
    required this.title,
    required this.description,
    required this.serviceCategory,
    this.industryId,
    this.industryName,
    required this.serviceType,
    required this.pricingModel,
    this.startingPrice,
    this.priceUnit,
    this.turnaroundTime,
    this.coverageArea,
    this.location,
    this.imagesJson,
    required this.isActive,
    required this.viewCount,
    required this.createdAtUtc,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    return ServiceSummary(
      id: json['id'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      providerName: json['providerName'] as String? ?? 'Service Provider',
      providerCompanyName: json['providerCompanyName'] as String?,
      providerCity: json['providerCity'] as String?,
      providerState: json['providerState'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      serviceCategory: json['serviceCategory'] as String? ?? 'General',
      industryId: json['industryId'] as int?,
      industryName: json['industryName'] as String?,
      serviceType: json['serviceType'] as String? ?? 'On-Site',
      pricingModel: json['pricingModel'] as String? ?? 'Quote-Based',
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      priceUnit: json['priceUnit'] as String?,
      turnaroundTime: json['turnaroundTime'] as String?,
      coverageArea: json['coverageArea'] as String?,
      location: json['location'] as String?,
      imagesJson: json['imagesJson'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final int id;
  final int memberId;
  final String providerName;
  final String? providerCompanyName;
  final String? providerCity;
  final String? providerState;
  final String title;
  final String description;
  final String serviceCategory;
  final int? industryId;
  final String? industryName;
  final String serviceType;
  final String pricingModel;
  final double? startingPrice;
  final String? priceUnit;
  final String? turnaroundTime;
  final String? coverageArea;
  final String? location;
  final String? imagesJson;
  final bool isActive;
  final int viewCount;
  final DateTime createdAtUtc;
}

class ServiceDetail {
  const ServiceDetail({
    required this.id,
    required this.memberId,
    required this.providerName,
    this.providerCompanyName,
    this.providerEmail,
    this.providerPhone,
    this.providerCity,
    this.providerState,
    required this.title,
    required this.description,
    required this.serviceCategory,
    this.industryId,
    this.industryName,
    this.businessGroupId,
    this.subGroupId,
    this.categoryId,
    required this.serviceType,
    required this.pricingModel,
    this.startingPrice,
    this.priceUnit,
    this.turnaroundTime,
    this.coverageArea,
    this.location,
    this.tagsJson,
    this.imagesJson,
    this.certifications,
    this.yearsOfExperience,
    required this.isActive,
    required this.viewCount,
    required this.createdAtUtc,
    this.updatedAtUtc,
    required this.inquiryCount,
    required this.isOwner,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    return ServiceDetail(
      id: json['id'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      providerName: json['providerName'] as String? ?? 'Service Provider',
      providerCompanyName: json['providerCompanyName'] as String?,
      providerEmail: json['providerEmail'] as String?,
      providerPhone: json['providerPhone'] as String?,
      providerCity: json['providerCity'] as String?,
      providerState: json['providerState'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      serviceCategory: json['serviceCategory'] as String? ?? 'General',
      industryId: json['industryId'] as int?,
      industryName: json['industryName'] as String?,
      businessGroupId: json['businessGroupId'] as int?,
      subGroupId: json['subGroupId'] as int?,
      categoryId: json['categoryId'] as int?,
      serviceType: json['serviceType'] as String? ?? 'On-Site',
      pricingModel: json['pricingModel'] as String? ?? 'Quote-Based',
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      priceUnit: json['priceUnit'] as String?,
      turnaroundTime: json['turnaroundTime'] as String?,
      coverageArea: json['coverageArea'] as String?,
      location: json['location'] as String?,
      tagsJson: json['tagsJson'] as String?,
      imagesJson: json['imagesJson'] as String?,
      certifications: json['certifications'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'] as String)
          : null,
      inquiryCount: json['inquiryCount'] as int? ?? 0,
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }

  final int id;
  final int memberId;
  final String providerName;
  final String? providerCompanyName;
  final String? providerEmail;
  final String? providerPhone;
  final String? providerCity;
  final String? providerState;
  final String title;
  final String description;
  final String serviceCategory;
  final int? industryId;
  final String? industryName;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String serviceType;
  final String pricingModel;
  final double? startingPrice;
  final String? priceUnit;
  final String? turnaroundTime;
  final String? coverageArea;
  final String? location;
  final String? tagsJson;
  final String? imagesJson;
  final String? certifications;
  final int? yearsOfExperience;
  final bool isActive;
  final int viewCount;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final int inquiryCount;
  final bool isOwner;
}

class CreateServiceRequest {
  const CreateServiceRequest({
    required this.title,
    required this.description,
    required this.serviceCategory,
    this.industryId,
    this.businessGroupId,
    this.subGroupId,
    this.categoryId,
    this.serviceType = 'On-Site',
    this.pricingModel = 'Quote-Based',
    this.startingPrice,
    this.priceUnit,
    this.turnaroundTime,
    this.coverageArea,
    this.location,
    this.tagsJson,
    this.imagesJson,
    this.certifications,
    this.yearsOfExperience,
  });

  final String title;
  final String description;
  final String serviceCategory;
  final int? industryId;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String serviceType;
  final String pricingModel;
  final double? startingPrice;
  final String? priceUnit;
  final String? turnaroundTime;
  final String? coverageArea;
  final String? location;
  final String? tagsJson;
  final String? imagesJson;
  final String? certifications;
  final int? yearsOfExperience;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'serviceCategory': serviceCategory.trim(),
        if (industryId != null) 'industryId': industryId,
        if (businessGroupId != null) 'businessGroupId': businessGroupId,
        if (subGroupId != null) 'subGroupId': subGroupId,
        if (categoryId != null) 'categoryId': categoryId,
        'serviceType': serviceType,
        'pricingModel': pricingModel,
        if (startingPrice != null) 'startingPrice': startingPrice,
        if (priceUnit != null) 'priceUnit': priceUnit,
        if (turnaroundTime != null) 'turnaroundTime': turnaroundTime,
        if (coverageArea != null) 'coverageArea': coverageArea,
        if (location != null) 'location': location,
        if (tagsJson != null) 'tagsJson': tagsJson,
        if (imagesJson != null) 'imagesJson': imagesJson,
        if (certifications != null) 'certifications': certifications,
        if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      };
}

class UpdateServiceRequest {
  const UpdateServiceRequest({
    required this.title,
    required this.description,
    required this.serviceCategory,
    this.industryId,
    this.businessGroupId,
    this.subGroupId,
    this.categoryId,
    this.serviceType = 'On-Site',
    this.pricingModel = 'Quote-Based',
    this.startingPrice,
    this.priceUnit,
    this.turnaroundTime,
    this.coverageArea,
    this.location,
    this.tagsJson,
    this.imagesJson,
    this.certifications,
    this.yearsOfExperience,
    this.isActive = true,
  });

  final String title;
  final String description;
  final String serviceCategory;
  final int? industryId;
  final int? businessGroupId;
  final int? subGroupId;
  final int? categoryId;
  final String serviceType;
  final String pricingModel;
  final double? startingPrice;
  final String? priceUnit;
  final String? turnaroundTime;
  final String? coverageArea;
  final String? location;
  final String? tagsJson;
  final String? imagesJson;
  final String? certifications;
  final int? yearsOfExperience;
  final bool? isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'serviceCategory': serviceCategory.trim(),
        if (industryId != null) 'industryId': industryId,
        if (businessGroupId != null) 'businessGroupId': businessGroupId,
        if (subGroupId != null) 'subGroupId': subGroupId,
        if (categoryId != null) 'categoryId': categoryId,
        'serviceType': serviceType,
        'pricingModel': pricingModel,
        if (startingPrice != null) 'startingPrice': startingPrice,
        if (priceUnit != null) 'priceUnit': priceUnit,
        if (turnaroundTime != null) 'turnaroundTime': turnaroundTime,
        if (coverageArea != null) 'coverageArea': coverageArea,
        if (location != null) 'location': location,
        if (tagsJson != null) 'tagsJson': tagsJson,
        if (imagesJson != null) 'imagesJson': imagesJson,
        if (certifications != null) 'certifications': certifications,
        if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
        if (isActive != null) 'isActive': isActive,
      };
}

class ServiceInquiryStatusHistory {
  const ServiceInquiryStatusHistory({
    required this.id,
    this.previousStatus,
    required this.newStatus,
    required this.statusName,
    required this.changedByMemberId,
    required this.changedByName,
    required this.changedAtUtc,
    this.remarks,
  });

  factory ServiceInquiryStatusHistory.fromJson(Map<String, dynamic> json) {
    return ServiceInquiryStatusHistory(
      id: json['id'] as int? ?? 0,
      previousStatus: json['previousStatus'] != null
          ? ServiceInquiryStatus.fromInt(json['previousStatus'] as int)
          : null,
      newStatus: ServiceInquiryStatus.fromInt(json['newStatus'] as int? ?? 1),
      statusName: json['statusName'] as String? ?? 'Pending',
      changedByMemberId: json['changedByMemberId'] as int? ?? 0,
      changedByName: json['changedByName'] as String? ?? 'Member',
      changedAtUtc: DateTime.tryParse(json['changedAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      remarks: json['remarks'] as String?,
    );
  }

  final int id;
  final ServiceInquiryStatus? previousStatus;
  final ServiceInquiryStatus newStatus;
  final String statusName;
  final int changedByMemberId;
  final String changedByName;
  final DateTime changedAtUtc;
  final String? remarks;
}

class ServiceInquiry {
  const ServiceInquiry({
    required this.id,
    required this.inquiryNumber,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceCategory,
    required this.senderMemberId,
    required this.senderName,
    this.senderCompanyName,
    this.senderEmail,
    this.senderPhone,
    required this.recipientMemberId,
    required this.recipientName,
    this.recipientCompanyName,
    required this.subject,
    required this.requirementDescription,
    this.scopeOfWork,
    this.location,
    this.preferredStartDate,
    this.estimatedBudget,
    required this.urgency,
    required this.status,
    required this.statusName,
    this.responseMessage,
    this.respondedAtUtc,
    required this.createdAtUtc,
    this.statusHistory = const <ServiceInquiryStatusHistory>[],
  });

  factory ServiceInquiry.fromJson(Map<String, dynamic> json) {
    return ServiceInquiry(
      id: json['id'] as int? ?? 0,
      inquiryNumber: json['inquiryNumber'] as String? ?? '',
      serviceId: json['serviceId'] as int? ?? 0,
      serviceTitle: json['serviceTitle'] as String? ?? '',
      serviceCategory: json['serviceCategory'] as String? ?? '',
      senderMemberId: json['senderMemberId'] as int? ?? 0,
      senderName: json['senderName'] as String? ?? 'Client',
      senderCompanyName: json['senderCompanyName'] as String?,
      senderEmail: json['senderEmail'] as String?,
      senderPhone: json['senderPhone'] as String?,
      recipientMemberId: json['recipientMemberId'] as int? ?? 0,
      recipientName: json['recipientName'] as String? ?? 'Provider',
      recipientCompanyName: json['recipientCompanyName'] as String?,
      subject: json['subject'] as String? ?? '',
      requirementDescription: json['requirementDescription'] as String? ?? '',
      scopeOfWork: json['scopeOfWork'] as String?,
      location: json['location'] as String?,
      preferredStartDate: json['preferredStartDate'] != null
          ? DateTime.tryParse(json['preferredStartDate'] as String)
          : null,
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble(),
      urgency: json['urgency'] as String? ?? 'Normal',
      status: json['status'] is int
          ? ServiceInquiryStatus.fromInt(json['status'] as int)
          : ServiceInquiryStatus.fromString(json['status'] as String?),
      statusName: json['statusName'] as String? ?? 'Pending',
      responseMessage: json['responseMessage'] as String?,
      respondedAtUtc: json['respondedAtUtc'] != null
          ? DateTime.tryParse(json['respondedAtUtc'] as String)
          : null,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((item) => ServiceInquiryStatusHistory.fromJson(
                  item as Map<String, dynamic>))
              .toList() ??
          const <ServiceInquiryStatusHistory>[],
    );
  }

  final int id;
  final String inquiryNumber;
  final int serviceId;
  final String serviceTitle;
  final String serviceCategory;
  final int senderMemberId;
  final String senderName;
  final String? senderCompanyName;
  final String? senderEmail;
  final String? senderPhone;
  final int recipientMemberId;
  final String recipientName;
  final String? recipientCompanyName;
  final String subject;
  final String requirementDescription;
  final String? scopeOfWork;
  final String? location;
  final DateTime? preferredStartDate;
  final double? estimatedBudget;
  final String urgency;
  final ServiceInquiryStatus status;
  final String statusName;
  final String? responseMessage;
  final DateTime? respondedAtUtc;
  final DateTime createdAtUtc;
  final List<ServiceInquiryStatusHistory> statusHistory;
}

class CreateServiceInquiryRequest {
  const CreateServiceInquiryRequest({
    required this.serviceId,
    required this.subject,
    required this.requirementDescription,
    this.scopeOfWork,
    this.location,
    this.preferredStartDate,
    this.estimatedBudget,
    this.urgency = 'Normal',
  });

  final int serviceId;
  final String subject;
  final String requirementDescription;
  final String? scopeOfWork;
  final String? location;
  final DateTime? preferredStartDate;
  final double? estimatedBudget;
  final String urgency;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'serviceId': serviceId,
        'subject': subject.trim(),
        'requirementDescription': requirementDescription.trim(),
        if (scopeOfWork != null && scopeOfWork!.isNotEmpty)
          'scopeOfWork': scopeOfWork!.trim(),
        if (location != null && location!.isNotEmpty)
          'location': location!.trim(),
        if (preferredStartDate != null)
          'preferredStartDate': preferredStartDate!.toIso8601String(),
        if (estimatedBudget != null) 'estimatedBudget': estimatedBudget,
        'urgency': urgency,
      };
}

class RespondServiceInquiryRequest {
  const RespondServiceInquiryRequest({
    required this.responseMessage,
    this.acceptInquiry = true,
  });

  final String responseMessage;
  final bool acceptInquiry;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'responseMessage': responseMessage.trim(),
        'acceptInquiry': acceptInquiry,
      };
}

