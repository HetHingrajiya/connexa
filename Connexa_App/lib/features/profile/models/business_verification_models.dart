/// Models representing business verification entities and lifecycle states.
library;

enum VerificationStatus {
  notSubmitted,
  pendingReview,
  approved,
  rejected;

  static VerificationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pendingreview':
      case 'pending_review':
      case 'pending':
        return VerificationStatus.pendingReview;
      case 'approved':
      case 'verified':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.notSubmitted;
    }
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'Not Verified';
      case VerificationStatus.pendingReview:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

class BusinessVerificationDocument {
  const BusinessVerificationDocument({
    required this.id,
    required this.verificationRequestId,
    required this.documentType,
    required this.originalFileName,
    required this.fileExtension,
    required this.contentType,
    required this.fileSizeBytes,
    required this.uploadedAtUtc,
    required this.downloadUrl,
  });

  final int id;
  final int verificationRequestId;
  final String documentType;
  final String originalFileName;
  final String fileExtension;
  final String contentType;
  final int fileSizeBytes;
  final DateTime uploadedAtUtc;
  final String downloadUrl;

  factory BusinessVerificationDocument.fromJson(Map<String, dynamic> json) {
    return BusinessVerificationDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      verificationRequestId:
          (json['verificationRequestId'] as num?)?.toInt() ?? 0,
      documentType: json['documentType']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? '',
      fileExtension: json['fileExtension']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAtUtc:
          DateTime.tryParse(json['uploadedAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      downloadUrl: json['downloadUrl']?.toString() ?? '',
    );
  }
}

class BusinessVerificationRequest {
  const BusinessVerificationRequest({
    required this.id,
    required this.businessProfileId,
    required this.companyName,
    required this.memberId,
    required this.ownerFullName,
    required this.ownerEmail,
    required this.ownerPhoneNumber,
    required this.status,
    required this.businessRegistrationNumber,
    required this.registeredAddress,
    required this.city,
    required this.state,
    required this.pincode,
    this.notes,
    required this.submittedAtUtc,
    this.reviewedAtUtc,
    this.reviewedByMemberId,
    this.rejectionReason,
    required this.documents,
  });

  final int id;
  final int businessProfileId;
  final String companyName;
  final int memberId;
  final String ownerFullName;
  final String ownerEmail;
  final String ownerPhoneNumber;
  final VerificationStatus status;
  final String businessRegistrationNumber;
  final String registeredAddress;
  final String city;
  final String state;
  final String pincode;
  final String? notes;
  final DateTime submittedAtUtc;
  final DateTime? reviewedAtUtc;
  final int? reviewedByMemberId;
  final String? rejectionReason;
  final List<BusinessVerificationDocument> documents;

  factory BusinessVerificationRequest.fromJson(Map<String, dynamic> json) {
    final dynamic rawDocs = json['documents'];
    final List<BusinessVerificationDocument> docs = <BusinessVerificationDocument>[];
    if (rawDocs is List) {
      for (final dynamic item in rawDocs) {
        if (item is Map<String, dynamic>) {
          docs.add(BusinessVerificationDocument.fromJson(item));
        }
      }
    }

    return BusinessVerificationRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessProfileId: (json['businessProfileId'] as num?)?.toInt() ?? 0,
      companyName: json['companyName']?.toString() ?? '',
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      ownerFullName: json['ownerFullName']?.toString() ?? '',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      ownerPhoneNumber: json['ownerPhoneNumber']?.toString() ?? '',
      status: VerificationStatus.fromString(json['status']?.toString()),
      businessRegistrationNumber:
          json['businessRegistrationNumber']?.toString() ?? '',
      registeredAddress: json['registeredAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      notes: json['notes']?.toString(),
      submittedAtUtc:
          DateTime.tryParse(json['submittedAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAtUtc: DateTime.tryParse(json['reviewedAtUtc']?.toString() ?? ''),
      reviewedByMemberId: (json['reviewedByMemberId'] as num?)?.toInt(),
      rejectionReason: json['rejectionReason']?.toString(),
      documents: docs,
    );
  }
}

class VerificationStatusResponse {
  const VerificationStatusResponse({
    required this.status,
    required this.isVerified,
    this.latestRequestId,
    this.submittedAtUtc,
    this.reviewedAtUtc,
    this.rejectionReason,
    this.latestRequest,
  });

  final VerificationStatus status;
  final bool isVerified;
  final int? latestRequestId;
  final DateTime? submittedAtUtc;
  final DateTime? reviewedAtUtc;
  final String? rejectionReason;
  final BusinessVerificationRequest? latestRequest;

  factory VerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? reqMap =
        json['latestRequest'] as Map<String, dynamic>?;

    return VerificationStatusResponse(
      status: VerificationStatus.fromString(json['status']?.toString()),
      isVerified: json['isVerified'] as bool? ?? false,
      latestRequestId: (json['latestRequestId'] as num?)?.toInt(),
      submittedAtUtc: DateTime.tryParse(
        json['submittedAtUtc']?.toString() ?? '',
      ),
      reviewedAtUtc: DateTime.tryParse(json['reviewedAtUtc']?.toString() ?? ''),
      rejectionReason: json['rejectionReason']?.toString(),
      latestRequest:
          reqMap != null ? BusinessVerificationRequest.fromJson(reqMap) : null,
    );
  }
}

class AdminVerificationListResponse {
  const AdminVerificationListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<BusinessVerificationRequest> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory AdminVerificationListResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];
    final List<BusinessVerificationRequest> list = <BusinessVerificationRequest>[];
    if (rawItems is List) {
      for (final dynamic item in rawItems) {
        if (item is Map<String, dynamic>) {
          list.add(BusinessVerificationRequest.fromJson(item));
        }
      }
    }

    return AdminVerificationListResponse(
      items: list,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class DocumentUploadItem {
  const DocumentUploadItem({
    required this.fileName,
    required this.documentType,
    required this.bytes,
    this.contentType = 'application/pdf',
  });

  final String fileName;
  final String documentType;
  final List<int> bytes;
  final String contentType;
}
