import 'package:flutter/foundation.dart';

enum RfqStatus {
  open,
  quotationReceived,
  closed,
  cancelled;

  String get label {
    switch (this) {
      case RfqStatus.open:
        return 'Open';
      case RfqStatus.quotationReceived:
        return 'Quote Received';
      case RfqStatus.closed:
        return 'Closed';
      case RfqStatus.cancelled:
        return 'Cancelled';
    }
  }

  static RfqStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'open':
        return RfqStatus.open;
      case 'quotationreceived':
        return RfqStatus.quotationReceived;
      case 'closed':
        return RfqStatus.closed;
      case 'cancelled':
        return RfqStatus.cancelled;
      default:
        return RfqStatus.open;
    }
  }
}

enum QuotationStatus {
  draft,
  submitted,
  revised,
  accepted,
  rejected,
  expired;

  String get label {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.submitted:
        return 'Submitted';
      case QuotationStatus.revised:
        return 'Revised';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
    }
  }

  static QuotationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'draft':
        return QuotationStatus.draft;
      case 'submitted':
        return QuotationStatus.submitted;
      case 'revised':
        return QuotationStatus.revised;
      case 'accepted':
        return QuotationStatus.accepted;
      case 'rejected':
        return QuotationStatus.rejected;
      case 'expired':
        return QuotationStatus.expired;
      default:
        return QuotationStatus.submitted;
    }
  }
}

@immutable
class Quotation {
  const Quotation({
    required this.id,
    required this.rfqId,
    required this.rfqNumber,
    required this.quotationNumber,
    required this.version,
    required this.supplierMemberId,
    required this.supplierName,
    required this.supplierCompanyName,
    required this.buyerMemberId,
    required this.buyerName,
    required this.buyerCompanyName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.shippingCharges,
    required this.totalAmount,
    required this.validUntilUtc,
    required this.estimatedDeliveryTime,
    this.termsAndConditions,
    this.documentUrl,
    required this.status,
    this.rejectionReason,
    this.revisionNotes,
    required this.createdAtUtc,
    this.submittedAtUtc,
    this.decidedAtUtc,
    this.isExpired = false,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as int? ?? 0,
      rfqId: json['rfqId'] as int? ?? 0,
      rfqNumber: json['rfqNumber'] as String? ?? '',
      quotationNumber: json['quotationNumber'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      supplierMemberId: json['supplierMemberId'] as int? ?? 0,
      supplierName: json['supplierName'] as String? ?? '',
      supplierCompanyName: json['supplierCompanyName'] as String? ?? '',
      buyerMemberId: json['buyerMemberId'] as int? ?? 0,
      buyerName: json['buyerName'] as String? ?? '',
      buyerCompanyName: json['buyerCompanyName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRatePercent: (json['taxRatePercent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingCharges: (json['shippingCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      validUntilUtc: json['validUntilUtc'] != null
          ? DateTime.tryParse(json['validUntilUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as String? ?? '',
      termsAndConditions: json['termsAndConditions'] as String?,
      documentUrl: json['documentUrl'] as String?,
      status: QuotationStatus.fromString(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      revisionNotes: json['revisionNotes'] as String?,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
      submittedAtUtc: json['submittedAtUtc'] != null
          ? DateTime.tryParse(json['submittedAtUtc'] as String)
          : null,
      decidedAtUtc: json['decidedAtUtc'] != null
          ? DateTime.tryParse(json['decidedAtUtc'] as String)
          : null,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }

  final int id;
  final int rfqId;
  final String rfqNumber;
  final String quotationNumber;
  final int version;
  final int supplierMemberId;
  final String supplierName;
  final String supplierCompanyName;
  final int buyerMemberId;
  final String buyerName;
  final String buyerCompanyName;
  final double unitPrice;
  final double quantity;
  final double subtotal;
  final double taxRatePercent;
  final double taxAmount;
  final double shippingCharges;
  final double totalAmount;
  final DateTime validUntilUtc;
  final String estimatedDeliveryTime;
  final String? termsAndConditions;
  final String? documentUrl;
  final QuotationStatus status;
  final String? rejectionReason;
  final String? revisionNotes;
  final DateTime createdAtUtc;
  final DateTime? submittedAtUtc;
  final DateTime? decidedAtUtc;
  final bool isExpired;

  bool get canBeDecided =>
      status == QuotationStatus.submitted &&
      !isExpired &&
      validUntilUtc.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'rfqId': rfqId,
        'rfqNumber': rfqNumber,
        'quotationNumber': quotationNumber,
        'version': version,
        'supplierMemberId': supplierMemberId,
        'supplierName': supplierName,
        'supplierCompanyName': supplierCompanyName,
        'buyerMemberId': buyerMemberId,
        'buyerName': buyerName,
        'buyerCompanyName': buyerCompanyName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
        'taxRatePercent': taxRatePercent,
        'taxAmount': taxAmount,
        'shippingCharges': shippingCharges,
        'totalAmount': totalAmount,
        'validUntilUtc': validUntilUtc.toIso8601String(),
        'estimatedDeliveryTime': estimatedDeliveryTime,
        'termsAndConditions': termsAndConditions,
        'documentUrl': documentUrl,
        'status': status.name,
        'rejectionReason': rejectionReason,
        'revisionNotes': revisionNotes,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'submittedAtUtc': submittedAtUtc?.toIso8601String(),
        'decidedAtUtc': decidedAtUtc?.toIso8601String(),
        'isExpired': isExpired,
      };
}

@immutable
class Rfq {
  const Rfq({
    required this.id,
    required this.rfqNumber,
    required this.productId,
    required this.productName,
    this.productThumbnailUrl,
    required this.buyerMemberId,
    required this.buyerFullName,
    required this.buyerCompanyName,
    this.buyerEmail,
    this.buyerPhone,
    required this.supplierMemberId,
    required this.supplierFullName,
    required this.supplierCompanyName,
    required this.title,
    required this.quantity,
    required this.unitOfMeasurement,
    this.targetPrice,
    this.requiredDeliveryDateUtc,
    required this.deliveryLocation,
    this.additionalSpecifications,
    this.attachmentUrl,
    required this.status,
    required this.createdAtUtc,
    this.updatedAtUtc,
    this.closedAtUtc,
    this.quotationsCount = 0,
    this.latestQuotation,
    this.isBuyer = false,
    this.isSupplier = false,
  });

  factory Rfq.fromJson(Map<String, dynamic> json) {
    return Rfq(
      id: json['id'] as int? ?? 0,
      rfqNumber: json['rfqNumber'] as String? ?? '',
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      productThumbnailUrl: json['productThumbnailUrl'] as String?,
      buyerMemberId: json['buyerMemberId'] as int? ?? 0,
      buyerFullName: json['buyerFullName'] as String? ?? '',
      buyerCompanyName: json['buyerCompanyName'] as String? ?? '',
      buyerEmail: json['buyerEmail'] as String?,
      buyerPhone: json['buyerPhone'] as String?,
      supplierMemberId: json['supplierMemberId'] as int? ?? 0,
      supplierFullName: json['supplierFullName'] as String? ?? '',
      supplierCompanyName: json['supplierCompanyName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasurement: json['unitOfMeasurement'] as String? ?? '',
      targetPrice: (json['targetPrice'] as num?)?.toDouble(),
      requiredDeliveryDateUtc: json['requiredDeliveryDateUtc'] != null
          ? DateTime.tryParse(json['requiredDeliveryDateUtc'] as String)
          : null,
      deliveryLocation: json['deliveryLocation'] as String? ?? '',
      additionalSpecifications: json['additionalSpecifications'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      status: RfqStatus.fromString(json['status'] as String?),
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'] as String)
          : null,
      closedAtUtc: json['closedAtUtc'] != null
          ? DateTime.tryParse(json['closedAtUtc'] as String)
          : null,
      quotationsCount: json['quotationsCount'] as int? ?? 0,
      latestQuotation: json['latestQuotation'] != null
          ? Quotation.fromJson(json['latestQuotation'] as Map<String, dynamic>)
          : null,
      isBuyer: json['isBuyer'] as bool? ?? false,
      isSupplier: json['isSupplier'] as bool? ?? false,
    );
  }

  final int id;
  final String rfqNumber;
  final int productId;
  final String productName;
  final String? productThumbnailUrl;
  final int buyerMemberId;
  final String buyerFullName;
  final String buyerCompanyName;
  final String? buyerEmail;
  final String? buyerPhone;
  final int supplierMemberId;
  final String supplierFullName;
  final String supplierCompanyName;
  final String title;
  final double quantity;
  final String unitOfMeasurement;
  final double? targetPrice;
  final DateTime? requiredDeliveryDateUtc;
  final String deliveryLocation;
  final String? additionalSpecifications;
  final String? attachmentUrl;
  final RfqStatus status;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final DateTime? closedAtUtc;
  final int quotationsCount;
  final Quotation? latestQuotation;
  final bool isBuyer;
  final bool isSupplier;

  bool get isOpen => status == RfqStatus.open || status == RfqStatus.quotationReceived;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'rfqNumber': rfqNumber,
        'productId': productId,
        'productName': productName,
        'productThumbnailUrl': productThumbnailUrl,
        'buyerMemberId': buyerMemberId,
        'buyerFullName': buyerFullName,
        'buyerCompanyName': buyerCompanyName,
        'buyerEmail': buyerEmail,
        'buyerPhone': buyerPhone,
        'supplierMemberId': supplierMemberId,
        'supplierFullName': supplierFullName,
        'supplierCompanyName': supplierCompanyName,
        'title': title,
        'quantity': quantity,
        'unitOfMeasurement': unitOfMeasurement,
        'targetPrice': targetPrice,
        'requiredDeliveryDateUtc': requiredDeliveryDateUtc?.toIso8601String(),
        'deliveryLocation': deliveryLocation,
        'additionalSpecifications': additionalSpecifications,
        'attachmentUrl': attachmentUrl,
        'status': status.name,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc?.toIso8601String(),
        'closedAtUtc': closedAtUtc?.toIso8601String(),
        'quotationsCount': quotationsCount,
        'latestQuotation': latestQuotation?.toJson(),
        'isBuyer': isBuyer,
        'isSupplier': isSupplier,
      };
}

class CreateRfqRequest {
  const CreateRfqRequest({
    required this.productId,
    required this.quantity,
    required this.unitOfMeasurement,
    this.targetPrice,
    this.requiredDeliveryDateUtc,
    required this.deliveryLocation,
    this.additionalSpecifications,
    this.attachmentUrl,
    this.title,
    this.productInquiryId,
  });

  final int productId;
  final double quantity;
  final String unitOfMeasurement;
  final double? targetPrice;
  final DateTime? requiredDeliveryDateUtc;
  final String deliveryLocation;
  final String? additionalSpecifications;
  final String? attachmentUrl;
  final String? title;
  final int? productInquiryId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productId': productId,
        'quantity': quantity,
        'unitOfMeasurement': unitOfMeasurement,
        if (targetPrice != null) 'targetPrice': targetPrice,
        if (requiredDeliveryDateUtc != null)
          'requiredDeliveryDateUtc': requiredDeliveryDateUtc!.toIso8601String(),
        'deliveryLocation': deliveryLocation,
        if (additionalSpecifications != null && additionalSpecifications!.isNotEmpty)
          'additionalSpecifications': additionalSpecifications,
        if (attachmentUrl != null && attachmentUrl!.isNotEmpty)
          'attachmentUrl': attachmentUrl,
        if (title != null && title!.isNotEmpty) 'title': title,
        if (productInquiryId != null) 'productInquiryId': productInquiryId,
      };
}

class SubmitQuotationRequest {
  const SubmitQuotationRequest({
    required this.unitPrice,
    required this.quantity,
    this.taxRatePercent = 18.0,
    this.shippingCharges = 0.0,
    this.validUntilUtc,
    this.estimatedDeliveryTime = '7 to 10 Business Days',
    this.termsAndConditions,
    this.documentUrl,
  });

  final double unitPrice;
  final double quantity;
  final double taxRatePercent;
  final double shippingCharges;
  final DateTime? validUntilUtc;
  final String estimatedDeliveryTime;
  final String? termsAndConditions;
  final String? documentUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'unitPrice': unitPrice,
        'quantity': quantity,
        'taxRatePercent': taxRatePercent,
        'shippingCharges': shippingCharges,
        if (validUntilUtc != null) 'validUntilUtc': validUntilUtc!.toIso8601String(),
        'estimatedDeliveryTime': estimatedDeliveryTime,
        if (termsAndConditions != null && termsAndConditions!.isNotEmpty)
          'termsAndConditions': termsAndConditions,
        if (documentUrl != null && documentUrl!.isNotEmpty)
          'documentUrl': documentUrl,
      };
}

class DecideQuotationRequest {
  const DecideQuotationRequest({
    required this.decision,
    this.notes,
  });

  final String decision; // 'Accept', 'Reject', 'RequestRevision'
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'decision': decision,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

String formatRfqDate(DateTime? dt) {
  if (dt == null) return '';
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final int monthIndex = (dt.month - 1).clamp(0, 11);
  return '${months[monthIndex]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
}

class RfqListResponse {
  const RfqListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory RfqListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    return RfqListResponse(
      items: rawItems
          .map((dynamic item) => Rfq.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  final List<Rfq> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}
