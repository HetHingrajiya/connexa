import 'package:flutter/material.dart';

enum OrderStatus {
  pendingConfirmation,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  rejected;

  String get label {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return 'Pending Confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return const Color(0xFFD97706); // Amber 600
      case OrderStatus.confirmed:
        return const Color(0xFF2563EB); // Blue 600
      case OrderStatus.processing:
        return const Color(0xFF7C3AED); // Purple 600
      case OrderStatus.shipped:
        return const Color(0xFF0284C7); // Sky 600
      case OrderStatus.delivered:
        return const Color(0xFF16A34A); // Green 600
      case OrderStatus.cancelled:
        return const Color(0xFF6B7280); // Gray 500
      case OrderStatus.rejected:
        return const Color(0xFFDC2626); // Red 600
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return const Color(0xFFFEF3C7);
      case OrderStatus.confirmed:
        return const Color(0xFFDBEAFE);
      case OrderStatus.processing:
        return const Color(0xFFEDE9FE);
      case OrderStatus.shipped:
        return const Color(0xFFE0F2FE);
      case OrderStatus.delivered:
        return const Color(0xFFDCFCE7);
      case OrderStatus.cancelled:
        return const Color(0xFFF3F4F6);
      case OrderStatus.rejected:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.processing:
        return Icons.precision_manufacturing_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.highlight_off_rounded;
    }
  }

  static OrderStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pendingconfirmation':
        return OrderStatus.pendingConfirmation;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'rejected':
        return OrderStatus.rejected;
      default:
        return OrderStatus.pendingConfirmation;
    }
  }
}

String formatOrderDate(DateTime? dt) {
  if (dt == null) return '';
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final int monthIndex = (dt.month - 1).clamp(0, 11);
  return '${months[monthIndex]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
}

String formatOrderDateTime(DateTime? dt) {
  if (dt == null) return '';
  final date = formatOrderDate(dt);
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$date at $hour:$minute';
}

String formatOrderCurrency(num? amount) {
  if (amount == null) return '₹0.00';
  return '₹${amount.toStringAsFixed(2)}';
}

@immutable
class OrderStatusHistory {
  const OrderStatusHistory({
    required this.id,
    required this.orderId,
    this.previousStatus,
    required this.newStatus,
    required this.changedByMemberId,
    required this.changedByMemberName,
    this.changedByCompanyName,
    required this.changedAtUtc,
    this.remarks,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String? ?? '',
      changedByMemberId: json['changedByMemberId'] as int? ?? 0,
      changedByMemberName: json['changedByMemberName'] as String? ?? 'User',
      changedByCompanyName: json['changedByCompanyName'] as String?,
      changedAtUtc: json['changedAtUtc'] != null
          ? DateTime.tryParse(json['changedAtUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
      remarks: json['remarks'] as String?,
    );
  }

  final int id;
  final int orderId;
  final String? previousStatus;
  final String newStatus;
  final int changedByMemberId;
  final String changedByMemberName;
  final String? changedByCompanyName;
  final DateTime changedAtUtc;
  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'orderId': orderId,
        'previousStatus': previousStatus,
        'newStatus': newStatus,
        'changedByMemberId': changedByMemberId,
        'changedByMemberName': changedByMemberName,
        'changedByCompanyName': changedByCompanyName,
        'changedAtUtc': changedAtUtc.toIso8601String(),
        'remarks': remarks,
      };
}

@immutable
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.quotationId,
    required this.quotationNumber,
    required this.rfqId,
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
    this.supplierEmail,
    this.supplierPhone,
    required this.quantity,
    required this.unitOfMeasurement,
    required this.unitPrice,
    required this.subtotal,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.shippingCharges,
    required this.totalAmount,
    this.termsAndConditionsSnapshot,
    required this.deliveryAddress,
    this.expectedDeliveryDateUtc,
    this.carrierName,
    this.trackingNumber,
    this.trackingUrl,
    this.shippedAtUtc,
    this.deliveredAtUtc,
    required this.status,
    this.cancellationReason,
    this.rejectionReason,
    this.notes,
    required this.createdAtUtc,
    this.updatedAtUtc,
    this.confirmedAtUtc,
    this.cancelledAtUtc,
    this.statusHistory = const <OrderStatusHistory>[],
    this.isBuyer = false,
    this.isSupplier = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['statusHistory'] as List<dynamic>? ?? <dynamic>[];
    return Order(
      id: json['id'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      quotationId: json['quotationId'] as int? ?? 0,
      quotationNumber: json['quotationNumber'] as String? ?? '',
      rfqId: json['rfqId'] as int? ?? 0,
      rfqNumber: json['rfqNumber'] as String? ?? '',
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? 'Product',
      productThumbnailUrl: json['productThumbnailUrl'] as String?,
      buyerMemberId: json['buyerMemberId'] as int? ?? 0,
      buyerFullName: json['buyerFullName'] as String? ?? '',
      buyerCompanyName: json['buyerCompanyName'] as String? ?? '',
      buyerEmail: json['buyerEmail'] as String?,
      buyerPhone: json['buyerPhone'] as String?,
      supplierMemberId: json['supplierMemberId'] as int? ?? 0,
      supplierFullName: json['supplierFullName'] as String? ?? '',
      supplierCompanyName: json['supplierCompanyName'] as String? ?? '',
      supplierEmail: json['supplierEmail'] as String?,
      supplierPhone: json['supplierPhone'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasurement: json['unitOfMeasurement'] as String? ?? 'Units',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRatePercent: (json['taxRatePercent'] as num?)?.toDouble() ?? 18.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingCharges: (json['shippingCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      termsAndConditionsSnapshot: json['termsAndConditionsSnapshot'] as String?,
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      expectedDeliveryDateUtc: json['expectedDeliveryDateUtc'] != null
          ? DateTime.tryParse(json['expectedDeliveryDateUtc'] as String)
          : null,
      carrierName: json['carrierName'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      trackingUrl: json['trackingUrl'] as String?,
      shippedAtUtc: json['shippedAtUtc'] != null
          ? DateTime.tryParse(json['shippedAtUtc'] as String)
          : null,
      deliveredAtUtc: json['deliveredAtUtc'] != null
          ? DateTime.tryParse(json['deliveredAtUtc'] as String)
          : null,
      status: OrderStatus.fromString(json['status'] as String?),
      cancellationReason: json['cancellationReason'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'] as String)
          : null,
      confirmedAtUtc: json['confirmedAtUtc'] != null
          ? DateTime.tryParse(json['confirmedAtUtc'] as String)
          : null,
      cancelledAtUtc: json['cancelledAtUtc'] != null
          ? DateTime.tryParse(json['cancelledAtUtc'] as String)
          : null,
      statusHistory: rawHistory
          .map((dynamic h) => OrderStatusHistory.fromJson(h as Map<String, dynamic>))
          .toList(),
      isBuyer: json['isBuyer'] as bool? ?? false,
      isSupplier: json['isSupplier'] as bool? ?? false,
    );
  }

  final int id;
  final String orderNumber;
  final int quotationId;
  final String quotationNumber;
  final int rfqId;
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
  final String? supplierEmail;
  final String? supplierPhone;
  final double quantity;
  final String unitOfMeasurement;
  final double unitPrice;
  final double subtotal;
  final double taxRatePercent;
  final double taxAmount;
  final double shippingCharges;
  final double totalAmount;
  final String? termsAndConditionsSnapshot;
  final String deliveryAddress;
  final DateTime? expectedDeliveryDateUtc;
  final String? carrierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? shippedAtUtc;
  final DateTime? deliveredAtUtc;
  final OrderStatus status;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final DateTime? confirmedAtUtc;
  final DateTime? cancelledAtUtc;
  final List<OrderStatusHistory> statusHistory;
  final bool isBuyer;
  final bool isSupplier;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'orderNumber': orderNumber,
        'quotationId': quotationId,
        'quotationNumber': quotationNumber,
        'rfqId': rfqId,
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
        'supplierEmail': supplierEmail,
        'supplierPhone': supplierPhone,
        'quantity': quantity,
        'unitOfMeasurement': unitOfMeasurement,
        'unitPrice': unitPrice,
        'subtotal': subtotal,
        'taxRatePercent': taxRatePercent,
        'taxAmount': taxAmount,
        'shippingCharges': shippingCharges,
        'totalAmount': totalAmount,
        'termsAndConditionsSnapshot': termsAndConditionsSnapshot,
        'deliveryAddress': deliveryAddress,
        'expectedDeliveryDateUtc': expectedDeliveryDateUtc?.toIso8601String(),
        'carrierName': carrierName,
        'trackingNumber': trackingNumber,
        'trackingUrl': trackingUrl,
        'shippedAtUtc': shippedAtUtc?.toIso8601String(),
        'deliveredAtUtc': deliveredAtUtc?.toIso8601String(),
        'status': status.name,
        'cancellationReason': cancellationReason,
        'rejectionReason': rejectionReason,
        'notes': notes,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc?.toIso8601String(),
        'confirmedAtUtc': confirmedAtUtc?.toIso8601String(),
        'cancelledAtUtc': cancelledAtUtc?.toIso8601String(),
        'statusHistory': statusHistory.map((OrderStatusHistory h) => h.toJson()).toList(),
        'isBuyer': isBuyer,
        'isSupplier': isSupplier,
      };
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.quotationId,
    required this.deliveryAddress,
    this.expectedDeliveryDateUtc,
    this.notes,
  });

  final int quotationId;
  final String deliveryAddress;
  final DateTime? expectedDeliveryDateUtc;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'quotationId': quotationId,
        'deliveryAddress': deliveryAddress,
        if (expectedDeliveryDateUtc != null)
          'expectedDeliveryDateUtc': expectedDeliveryDateUtc!.toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class ConfirmOrderRequest {
  const ConfirmOrderRequest({this.remarks});

  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class RejectOrderRequest {
  const RejectOrderRequest({
    required this.reason,
    this.remarks,
  });

  final String reason;
  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reason': reason,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class ProcessOrderRequest {
  const ProcessOrderRequest({this.remarks});

  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class ShipOrderRequest {
  const ShipOrderRequest({
    required this.carrierName,
    required this.trackingNumber,
    this.trackingUrl,
    this.remarks,
  });

  final String carrierName;
  final String trackingNumber;
  final String? trackingUrl;
  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'carrierName': carrierName,
        'trackingNumber': trackingNumber,
        if (trackingUrl != null && trackingUrl!.isNotEmpty)
          'trackingUrl': trackingUrl,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class DeliverOrderRequest {
  const DeliverOrderRequest({this.remarks});

  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class CancelOrderRequest {
  const CancelOrderRequest({
    required this.reason,
    this.remarks,
  });

  final String reason;
  final String? remarks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reason': reason,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      };
}

class OrderListResponse {
  const OrderListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory OrderListResponse.fromResponseData(dynamic rawData, [int? totalCount]) {
    if (rawData is List) {
      final items = rawData
          .map((dynamic item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
      return OrderListResponse(
        items: items,
        totalCount: totalCount ?? items.length,
        page: 1,
        pageSize: items.length,
        totalPages: 1,
      );
    } else if (rawData is Map<String, dynamic>) {
      final rawItems = rawData['items'] as List<dynamic>? ?? <dynamic>[];
      final items = rawItems
          .map((dynamic item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
      return OrderListResponse(
        items: items,
        totalCount: (rawData['totalCount'] as num?)?.toInt() ?? items.length,
        page: (rawData['page'] as num?)?.toInt() ?? 1,
        pageSize: (rawData['pageSize'] as num?)?.toInt() ?? 10,
        totalPages: (rawData['totalPages'] as num?)?.toInt() ?? 1,
      );
    }
    return const OrderListResponse(
      items: <Order>[],
      totalCount: 0,
      page: 1,
      pageSize: 10,
      totalPages: 0,
    );
  }

  final List<Order> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

