import 'package:flutter/foundation.dart';

enum JobWorkRequirementStatus {
  open,
  closed,
  cancelled;

  static JobWorkRequirementStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'closed':
        return JobWorkRequirementStatus.closed;
      case 'cancelled':
        return JobWorkRequirementStatus.cancelled;
      case 'open':
      default:
        return JobWorkRequirementStatus.open;
    }
  }

  String get label {
    switch (this) {
      case JobWorkRequirementStatus.open:
        return 'Open';
      case JobWorkRequirementStatus.closed:
        return 'Closed';
      case JobWorkRequirementStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum MaterialResponsibility {
  buyerSupplied,
  contractorSupplied,
  sharedOrNegotiable;

  static MaterialResponsibility fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'contractorsupplied':
      case 'contractor_supplied':
      case 'contractor':
        return MaterialResponsibility.contractorSupplied;
      case 'sharedornegotiable':
      case 'shared_or_negotiable':
      case 'negotiable':
        return MaterialResponsibility.sharedOrNegotiable;
      case 'buyersupplied':
      case 'buyer_supplied':
      case 'buyer':
      default:
        return MaterialResponsibility.buyerSupplied;
    }
  }

  String get label {
    switch (this) {
      case MaterialResponsibility.buyerSupplied:
        return 'Buyer Supplied';
      case MaterialResponsibility.contractorSupplied:
        return 'Contractor Supplied';
      case MaterialResponsibility.sharedOrNegotiable:
        return 'Negotiable / Shared';
    }
  }

  int get apiValue {
    switch (this) {
      case MaterialResponsibility.buyerSupplied:
        return 1;
      case MaterialResponsibility.contractorSupplied:
        return 2;
      case MaterialResponsibility.sharedOrNegotiable:
        return 3;
    }
  }
}

enum JobWorkQuotationStatus {
  submitted,
  revisionRequested,
  accepted,
  rejected,
  withdrawn;

  static JobWorkQuotationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'revisionrequested':
      case 'revision_requested':
      case 'revised':
        return JobWorkQuotationStatus.revisionRequested;
      case 'accepted':
        return JobWorkQuotationStatus.accepted;
      case 'rejected':
        return JobWorkQuotationStatus.rejected;
      case 'withdrawn':
        return JobWorkQuotationStatus.withdrawn;
      case 'submitted':
      default:
        return JobWorkQuotationStatus.submitted;
    }
  }

  String get label {
    switch (this) {
      case JobWorkQuotationStatus.submitted:
        return 'Submitted';
      case JobWorkQuotationStatus.revisionRequested:
        return 'Revision Requested';
      case JobWorkQuotationStatus.accepted:
        return 'Accepted';
      case JobWorkQuotationStatus.rejected:
        return 'Rejected';
      case JobWorkQuotationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

enum JobWorkOrderStatus {
  pendingConfirmation,
  confirmed,
  processing,
  completed,
  cancelled,
  rejected;

  static JobWorkOrderStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pendingconfirmation':
      case 'pending_confirmation':
        return JobWorkOrderStatus.pendingConfirmation;
      case 'confirmed':
        return JobWorkOrderStatus.confirmed;
      case 'processing':
        return JobWorkOrderStatus.processing;
      case 'completed':
        return JobWorkOrderStatus.completed;
      case 'cancelled':
        return JobWorkOrderStatus.cancelled;
      case 'rejected':
        return JobWorkOrderStatus.rejected;
      default:
        return JobWorkOrderStatus.confirmed;
    }
  }

  String get label {
    switch (this) {
      case JobWorkOrderStatus.pendingConfirmation:
        return 'Pending Confirmation';
      case JobWorkOrderStatus.confirmed:
        return 'Confirmed';
      case JobWorkOrderStatus.processing:
        return 'Processing';
      case JobWorkOrderStatus.completed:
        return 'Completed';
      case JobWorkOrderStatus.cancelled:
        return 'Cancelled';
      case JobWorkOrderStatus.rejected:
        return 'Rejected';
    }
  }

  int get apiValue {
    switch (this) {
      case JobWorkOrderStatus.pendingConfirmation:
        return 1;
      case JobWorkOrderStatus.confirmed:
        return 2;
      case JobWorkOrderStatus.processing:
        return 3;
      case JobWorkOrderStatus.completed:
        return 4;
      case JobWorkOrderStatus.cancelled:
        return 5;
      case JobWorkOrderStatus.rejected:
        return 6;
    }
  }
}

@immutable
class JobWorkAttachment {
  const JobWorkAttachment({
    required this.id,
    this.jobWorkRequirementId,
    this.jobWorkQuotationId,
    required this.uploadedByMemberId,
    required this.originalFileName,
    required this.storedFileName,
    required this.fileExtension,
    required this.contentType,
    required this.fileSizeBytes,
    required this.uploadedAtUtc,
    required this.downloadUrl,
  });

  factory JobWorkAttachment.fromJson(Map<String, dynamic> json) {
    return JobWorkAttachment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      jobWorkRequirementId: (json['jobWorkRequirementId'] as num?)?.toInt(),
      jobWorkQuotationId: (json['jobWorkQuotationId'] as num?)?.toInt(),
      uploadedByMemberId: (json['uploadedByMemberId'] as num?)?.toInt() ?? 0,
      originalFileName: json['originalFileName'] as String? ?? 'attachment',
      storedFileName: json['storedFileName'] as String? ?? '',
      fileExtension: json['fileExtension'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAtUtc: DateTime.tryParse(json['uploadedAtUtc'] as String? ?? '') ??
          DateTime.now(),
      downloadUrl: json['downloadUrl'] as String? ?? '',
    );
  }

  final int id;
  final int? jobWorkRequirementId;
  final int? jobWorkQuotationId;
  final int uploadedByMemberId;
  final String originalFileName;
  final String storedFileName;
  final String fileExtension;
  final String contentType;
  final int fileSizeBytes;
  final DateTime uploadedAtUtc;
  final String downloadUrl;

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

@immutable
class JobWorkRequirement {
  const JobWorkRequirement({
    required this.id,
    required this.requirementNumber,
    required this.ownerMemberId,
    required this.ownerFullName,
    required this.ownerCompanyName,
    this.ownerCity,
    this.ownerState,
    this.ownerIsVerified = false,
    required this.title,
    required this.description,
    required this.industryId,
    required this.industryName,
    this.businessGroupId,
    this.businessGroupName,
    this.subGroupId,
    this.subGroupName,
    this.categoryId,
    this.categoryName,
    required this.jobWorkProcess,
    this.machineType,
    this.machineCategory,
    this.requiredMachineCapacity,
    this.technicalSpecifications,
    this.requiredTolerance,
    this.materialType,
    required this.materialResponsibility,
    required this.quantity,
    required this.unitOfMeasurement,
    this.targetBudget,
    required this.location,
    this.deliveryTerms,
    this.targetCompletionDateUtc,
    required this.status,
    required this.createdAtUtc,
    this.updatedAtUtc,
    this.closedAtUtc,
    this.quotationsCount = 0,
    this.activeOrderId,
    this.activeOrderNumber,
    this.attachments = const <JobWorkAttachment>[],
    this.isOwner = false,
    this.hasQuoted = false,
    this.myQuotationId,
  });

  factory JobWorkRequirement.fromJson(Map<String, dynamic> json) {
    return JobWorkRequirement(
      id: (json['id'] as num?)?.toInt() ?? 0,
      requirementNumber: json['requirementNumber'] as String? ?? '',
      ownerMemberId: (json['ownerMemberId'] as num?)?.toInt() ?? 0,
      ownerFullName: json['ownerFullName'] as String? ?? 'Business Member',
      ownerCompanyName: json['ownerCompanyName'] as String? ?? 'Company',
      ownerCity: json['ownerCity'] as String?,
      ownerState: json['ownerState'] as String?,
      ownerIsVerified: json['ownerIsVerified'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      industryId: (json['industryId'] as num?)?.toInt() ?? 0,
      industryName: json['industryName'] as String? ?? 'General Manufacturing',
      businessGroupId: (json['businessGroupId'] as num?)?.toInt(),
      businessGroupName: json['businessGroupName'] as String?,
      subGroupId: (json['subGroupId'] as num?)?.toInt(),
      subGroupName: json['subGroupName'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      jobWorkProcess: json['jobWorkProcess'] as String? ?? 'Job Work',
      machineType: json['machineType'] as String?,
      machineCategory: json['machineCategory'] as String?,
      requiredMachineCapacity: json['requiredMachineCapacity'] as String?,
      technicalSpecifications: json['technicalSpecifications'] as String?,
      requiredTolerance: json['requiredTolerance'] as String?,
      materialType: json['materialType'] as String?,
      materialResponsibility: MaterialResponsibility.fromString(
        json['materialResponsibility'] as String?,
      ),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasurement: json['unitOfMeasurement'] as String? ?? 'Pieces',
      targetBudget: (json['targetBudget'] as num?)?.toDouble(),
      location: json['location'] as String? ?? 'Gujarat, India',
      deliveryTerms: json['deliveryTerms'] as String?,
      targetCompletionDateUtc: json['targetCompletionDateUtc'] != null
          ? DateTime.tryParse(json['targetCompletionDateUtc'] as String)
          : null,
      status: JobWorkRequirementStatus.fromString(json['status'] as String?),
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now(),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'] as String)
          : null,
      closedAtUtc: json['closedAtUtc'] != null
          ? DateTime.tryParse(json['closedAtUtc'] as String)
          : null,
      quotationsCount: (json['quotationsCount'] as num?)?.toInt() ?? 0,
      activeOrderId: (json['activeOrderId'] as num?)?.toInt(),
      activeOrderNumber: json['activeOrderNumber'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  JobWorkAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <JobWorkAttachment>[],
      isOwner: json['isOwner'] as bool? ?? false,
      hasQuoted: json['hasQuoted'] as bool? ?? false,
      myQuotationId: (json['myQuotationId'] as num?)?.toInt(),
    );
  }

  final int id;
  final String requirementNumber;
  final int ownerMemberId;
  final String ownerFullName;
  final String ownerCompanyName;
  final String? ownerCity;
  final String? ownerState;
  final bool ownerIsVerified;
  final String title;
  final String description;
  final int industryId;
  final String industryName;
  final int? businessGroupId;
  final String? businessGroupName;
  final int? subGroupId;
  final String? subGroupName;
  final int? categoryId;
  final String? categoryName;
  final String jobWorkProcess;
  final String? machineType;
  final String? machineCategory;
  final String? requiredMachineCapacity;
  final String? technicalSpecifications;
  final String? requiredTolerance;
  final String? materialType;
  final MaterialResponsibility materialResponsibility;
  final double quantity;
  final String unitOfMeasurement;
  final double? targetBudget;
  final String location;
  final String? deliveryTerms;
  final DateTime? targetCompletionDateUtc;
  final JobWorkRequirementStatus status;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final DateTime? closedAtUtc;
  final int quotationsCount;
  final int? activeOrderId;
  final String? activeOrderNumber;
  final List<JobWorkAttachment> attachments;
  final bool isOwner;
  final bool hasQuoted;
  final int? myQuotationId;

  String get formattedQuantity =>
      '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} $unitOfMeasurement';

  String get locationSummary {
    if (ownerCity != null && ownerState != null) {
      return '$ownerCity, $ownerState';
    }
    return location;
  }
}

@immutable
class JobWorkQuotation {
  const JobWorkQuotation({
    required this.id,
    required this.quotationNumber,
    required this.jobWorkRequirementId,
    required this.requirementNumber,
    required this.requirementTitle,
    required this.contractorMemberId,
    required this.contractorFullName,
    required this.contractorCompanyName,
    this.contractorCity,
    this.contractorState,
    this.contractorIsVerified = false,
    required this.offeredUnitPrice,
    required this.quantity,
    required this.subtotal,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.otherCharges,
    required this.totalAmount,
    required this.leadTimeDays,
    this.machineProposed,
    this.technicalRemarks,
    this.termsAndConditions,
    this.validUntilUtc,
    required this.status,
    this.revisionNumber = 1,
    this.rejectionReason,
    this.revisionNotes,
    required this.createdAtUtc,
    this.decidedAtUtc,
    this.attachments = const <JobWorkAttachment>[],
    this.isContractor = false,
    this.isOwner = false,
  });

  factory JobWorkQuotation.fromJson(Map<String, dynamic> json) {
    return JobWorkQuotation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      quotationNumber: json['quotationNumber'] as String? ?? '',
      jobWorkRequirementId:
          (json['jobWorkRequirementId'] as num?)?.toInt() ?? 0,
      requirementNumber: json['requirementNumber'] as String? ?? '',
      requirementTitle: json['requirementTitle'] as String? ?? '',
      contractorMemberId: (json['contractorMemberId'] as num?)?.toInt() ?? 0,
      contractorFullName: json['contractorFullName'] as String? ?? 'Contractor',
      contractorCompanyName:
          json['contractorCompanyName'] as String? ?? 'Contractor Firm',
      contractorCity: json['contractorCity'] as String?,
      contractorState: json['contractorState'] as String?,
      contractorIsVerified: json['contractorIsVerified'] as bool? ?? false,
      offeredUnitPrice: (json['offeredUnitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRatePercent: (json['taxRatePercent'] as num?)?.toDouble() ?? 18.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      leadTimeDays: (json['leadTimeDays'] as num?)?.toInt() ?? 7,
      machineProposed: json['machineProposed'] as String?,
      technicalRemarks: json['technicalRemarks'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
      validUntilUtc: json['validUntilUtc'] != null
          ? DateTime.tryParse(json['validUntilUtc'] as String)
          : null,
      status: JobWorkQuotationStatus.fromString(json['status'] as String?),
      revisionNumber: (json['revisionNumber'] as num?)?.toInt() ?? 1,
      rejectionReason: json['rejectionReason'] as String?,
      revisionNotes: json['revisionNotes'] as String?,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now(),
      decidedAtUtc: json['decidedAtUtc'] != null
          ? DateTime.tryParse(json['decidedAtUtc'] as String)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  JobWorkAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <JobWorkAttachment>[],
      isContractor: json['isContractor'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }

  final int id;
  final String quotationNumber;
  final int jobWorkRequirementId;
  final String requirementNumber;
  final String requirementTitle;
  final int contractorMemberId;
  final String contractorFullName;
  final String contractorCompanyName;
  final String? contractorCity;
  final String? contractorState;
  final bool contractorIsVerified;
  final double offeredUnitPrice;
  final double quantity;
  final double subtotal;
  final double taxRatePercent;
  final double taxAmount;
  final double otherCharges;
  final double totalAmount;
  final int leadTimeDays;
  final String? machineProposed;
  final String? technicalRemarks;
  final String? termsAndConditions;
  final DateTime? validUntilUtc;
  final JobWorkQuotationStatus status;
  final int revisionNumber;
  final String? rejectionReason;
  final String? revisionNotes;
  final DateTime createdAtUtc;
  final DateTime? decidedAtUtc;
  final List<JobWorkAttachment> attachments;
  final bool isContractor;
  final bool isOwner;

  String get formattedOfferedRate => '₹${offeredUnitPrice.toStringAsFixed(2)}';
  String get formattedTotal => '₹${totalAmount.toStringAsFixed(2)}';
  String get leadTimeFormatted => '$leadTimeDays ${leadTimeDays == 1 ? 'day' : 'days'}';
}

@immutable
class JobWorkOrderStatusHistory {
  const JobWorkOrderStatusHistory({
    required this.id,
    required this.jobWorkOrderId,
    this.previousStatus,
    required this.newStatus,
    required this.changedByMemberId,
    required this.changedByMemberName,
    this.changedByCompanyName,
    required this.changedAtUtc,
    this.remarks,
  });

  factory JobWorkOrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return JobWorkOrderStatusHistory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      jobWorkOrderId: (json['jobWorkOrderId'] as num?)?.toInt() ?? 0,
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String? ?? 'Confirmed',
      changedByMemberId: (json['changedByMemberId'] as num?)?.toInt() ?? 0,
      changedByMemberName: json['changedByMemberName'] as String? ?? 'Member',
      changedByCompanyName: json['changedByCompanyName'] as String?,
      changedAtUtc: DateTime.tryParse(json['changedAtUtc'] as String? ?? '') ??
          DateTime.now(),
      remarks: json['remarks'] as String?,
    );
  }

  final int id;
  final int jobWorkOrderId;
  final String? previousStatus;
  final String newStatus;
  final int changedByMemberId;
  final String changedByMemberName;
  final String? changedByCompanyName;
  final DateTime changedAtUtc;
  final String? remarks;
}

@immutable
class JobWorkOrder {
  const JobWorkOrder({
    required this.id,
    required this.orderNumber,
    required this.jobWorkRequirementId,
    required this.requirementNumber,
    required this.jobWorkQuotationId,
    required this.quotationNumber,
    required this.buyerMemberId,
    required this.buyerFullName,
    required this.buyerCompanyName,
    this.buyerEmail,
    this.buyerPhone,
    required this.contractorMemberId,
    required this.contractorFullName,
    required this.contractorCompanyName,
    this.contractorEmail,
    this.contractorPhone,
    required this.jobTitle,
    required this.process,
    required this.quantity,
    required this.unitOfMeasurement,
    required this.agreedUnitPrice,
    required this.subtotal,
    required this.taxAmount,
    required this.otherCharges,
    required this.totalAmount,
    required this.leadTimeDays,
    required this.deliveryLocation,
    required this.status,
    this.confirmedAtUtc,
    this.processingStartedAtUtc,
    this.completedAtUtc,
    this.cancelledAtUtc,
    this.cancellationReason,
    this.rejectionReason,
    this.notes,
    required this.createdAtUtc,
    this.statusHistory = const <JobWorkOrderStatusHistory>[],
    this.isBuyer = false,
    this.isContractor = false,
  });

  factory JobWorkOrder.fromJson(Map<String, dynamic> json) {
    return JobWorkOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      jobWorkRequirementId:
          (json['jobWorkRequirementId'] as num?)?.toInt() ?? 0,
      requirementNumber: json['requirementNumber'] as String? ?? '',
      jobWorkQuotationId: (json['jobWorkQuotationId'] as num?)?.toInt() ?? 0,
      quotationNumber: json['quotationNumber'] as String? ?? '',
      buyerMemberId: (json['buyerMemberId'] as num?)?.toInt() ?? 0,
      buyerFullName: json['buyerFullName'] as String? ?? 'Buyer',
      buyerCompanyName: json['buyerCompanyName'] as String? ?? 'Buyer Firm',
      buyerEmail: json['buyerEmail'] as String?,
      buyerPhone: json['buyerPhone'] as String?,
      contractorMemberId: (json['contractorMemberId'] as num?)?.toInt() ?? 0,
      contractorFullName: json['contractorFullName'] as String? ?? 'Contractor',
      contractorCompanyName:
          json['contractorCompanyName'] as String? ?? 'Contractor Firm',
      contractorEmail: json['contractorEmail'] as String?,
      contractorPhone: json['contractorPhone'] as String?,
      jobTitle: json['jobTitle'] as String? ?? '',
      process: json['process'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasurement: json['unitOfMeasurement'] as String? ?? 'Pieces',
      agreedUnitPrice: (json['agreedUnitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      leadTimeDays: (json['leadTimeDays'] as num?)?.toInt() ?? 7,
      deliveryLocation: json['deliveryLocation'] as String? ?? '',
      status: JobWorkOrderStatus.fromString(json['status'] as String?),
      confirmedAtUtc: json['confirmedAtUtc'] != null
          ? DateTime.tryParse(json['confirmedAtUtc'] as String)
          : null,
      processingStartedAtUtc: json['processingStartedAtUtc'] != null
          ? DateTime.tryParse(json['processingStartedAtUtc'] as String)
          : null,
      completedAtUtc: json['completedAtUtc'] != null
          ? DateTime.tryParse(json['completedAtUtc'] as String)
          : null,
      cancelledAtUtc: json['cancelledAtUtc'] != null
          ? DateTime.tryParse(json['cancelledAtUtc'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now(),
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((dynamic e) => JobWorkOrderStatusHistory.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const <JobWorkOrderStatusHistory>[],
      isBuyer: json['isBuyer'] as bool? ?? false,
      isContractor: json['isContractor'] as bool? ?? false,
    );
  }

  final int id;
  final String orderNumber;
  final int jobWorkRequirementId;
  final String requirementNumber;
  final int jobWorkQuotationId;
  final String quotationNumber;
  final int buyerMemberId;
  final String buyerFullName;
  final String buyerCompanyName;
  final String? buyerEmail;
  final String? buyerPhone;
  final int contractorMemberId;
  final String contractorFullName;
  final String contractorCompanyName;
  final String? contractorEmail;
  final String? contractorPhone;
  final String jobTitle;
  final String process;
  final double quantity;
  final String unitOfMeasurement;
  final double agreedUnitPrice;
  final double subtotal;
  final double taxAmount;
  final double otherCharges;
  final double totalAmount;
  final int leadTimeDays;
  final String deliveryLocation;
  final JobWorkOrderStatus status;
  final DateTime? confirmedAtUtc;
  final DateTime? processingStartedAtUtc;
  final DateTime? completedAtUtc;
  final DateTime? cancelledAtUtc;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAtUtc;
  final List<JobWorkOrderStatusHistory> statusHistory;
  final bool isBuyer;
  final bool isContractor;

  String get formattedTotal => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedRate => '₹${agreedUnitPrice.toStringAsFixed(2)}';
}

@immutable
class JobWorkRequirementListResponse {
  const JobWorkRequirementListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory JobWorkRequirementListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['items'] as List<dynamic>?;
    return JobWorkRequirementListResponse(
      items: rawItems
              ?.map((dynamic e) =>
                  JobWorkRequirement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <JobWorkRequirement>[],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final List<JobWorkRequirement> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

@immutable
class JobWorkQuotationListResponse {
  const JobWorkQuotationListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory JobWorkQuotationListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['items'] as List<dynamic>?;
    return JobWorkQuotationListResponse(
      items: rawItems
              ?.map((dynamic e) =>
                  JobWorkQuotation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <JobWorkQuotation>[],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final List<JobWorkQuotation> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

@immutable
class JobWorkOrderListResponse {
  const JobWorkOrderListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory JobWorkOrderListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['items'] as List<dynamic>?;
    return JobWorkOrderListResponse(
      items: rawItems
              ?.map((dynamic e) =>
                  JobWorkOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <JobWorkOrder>[],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final List<JobWorkOrder> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

