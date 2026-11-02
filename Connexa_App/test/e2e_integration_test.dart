import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/connections/models/connection_models.dart';
import 'package:connexa/features/notifications/models/notification_models.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/orders/models/order_models.dart';

void main() {
  group('E2E Integration Audit - Flutter Domain Models & Serialization', () {
    test('A. Authentication Models: AuthResponse and AuthenticatedMember roundtrip', () {
      final json = <String, dynamic>{
        'accessToken': 'jwt.access.token',
        'refreshToken': 'jwt.refresh.token',
        'tokenType': 'Bearer',
        'expiresIn': 900,
        'member': <String, dynamic>{
          'memberId': 42,
          'fullName': 'Test Business Owner',
          'email': 'owner@testcorp.com',
          'phoneNumber': '+919876543210',
          'role': 'Member',
          'primaryProfileType': 'BusinessCompany',
        },
      };

      final authResponse = AuthResponse.fromJson(json);
      expect(authResponse.accessToken, 'jwt.access.token');
      expect(authResponse.refreshToken, 'jwt.refresh.token');
      expect(authResponse.tokenType, 'Bearer');
      expect(authResponse.expiresIn, 900);
      expect(authResponse.member.memberId, 42);
      expect(authResponse.member.fullName, 'Test Business Owner');
      expect(authResponse.member.isAdmin, isFalse);
    });

    test('B. Business Profile & Verification Status Models', () {
      final profileJson = <String, dynamic>{
        'memberId': 42,
        'fullName': 'Test Business Owner',
        'countryCode': '+91',
        'phoneNumber': '+919876543210',
        'email': 'owner@testcorp.com',
        'primaryProfileType': 'BusinessCompany',
        'verifiedMethod': 'Email',
        'verifiedDestination': 'owner@testcorp.com',
        'role': 'Member',
        'isActive': true,
        'createdAtUtc': '2026-11-01T12:00:00Z',
        'profileDetails': <String, dynamic>{
          'companyName': 'Test Corp Ltd',
          'isVerified': true,
          'verificationStatus': 'Approved',
        },
      };

      final profile = MemberProfile.fromJson(profileJson);
      expect(profile.memberId, 42);
      expect(profile.fullName, 'Test Business Owner');
      expect(profile.isActive, isTrue);
      expect(profile.profileDetails, isNotNull);
    });

    test('C. Product Management Models: Product and Catalog Serialization', () {
      final productJson = <String, dynamic>{
        'id': 101,
        'memberId': 42,
        'name': 'CNC Vertical Lathe Machine',
        'description': 'High precision CNC lathe',
        'category': 'Industrial Machinery',
        'subCategory': 'Lathe Machines',
        'tags': <String>['CNC', 'Lathe', 'HeavyDuty'],
        'imageUrl': 'https://connexa.io/lathe.jpg',
        'specifications': <String, String>{
          'Spindle': '8000 RPM',
          'Chuck Size': '250 mm',
        },
        'industryId': 4,
        'industryName': 'Manufacturing',
        'companyName': 'Test Corp Ltd',
        'isOwnerVerified': true,
        'viewCount': 45,
        'inquiryCount': 3,
        'createdAtUtc': '2026-11-01T10:00:00Z',
      };

      final product = Product.fromJson(productJson);
      expect(product.id, 101);
      expect(product.name, 'CNC Vertical Lathe Machine');
      expect(product.category, 'Industrial Machinery');
      expect(product.tags, contains('CNC'));
      expect(product.isOwnerVerified, isTrue);
      expect(product.specifications['Spindle'], '8000 RPM');
    });

    test('D. Business Network & Connection Models', () {
      final itemJson = <String, dynamic>{
        'memberId': 42,
        'fullName': 'Supplier Alice',
        'companyName': 'Machinery Corp',
        'connectedAtUtc': '2026-11-01T09:30:00Z',
      };

      final connectedItem = ConnectedMemberItem.fromJson(itemJson);
      expect(connectedItem.memberId, 42);
      expect(connectedItem.fullName, 'Supplier Alice');
      expect(connectedItem.companyName, 'Machinery Corp');
    });

    test('E & F. RFQ and Quotation Management Models', () {
      final rfqJson = <String, dynamic>{
        'id': 301,
        'rfqNumber': 'RFQ-20261101-0001',
        'productId': 101,
        'productName': 'CNC Vertical Lathe Machine',
        'productThumbnailUrl': 'https://connexa.io/lathe.jpg',
        'buyerMemberId': 10,
        'buyerFullName': 'Buyer John',
        'buyerCompanyName': 'Procurement Inc',
        'supplierMemberId': 42,
        'supplierFullName': 'Supplier Alice',
        'supplierCompanyName': 'Machinery Corp',
        'title': 'Procurement of 2 Units CNC Lathe',
        'quantity': 2.0,
        'unitOfMeasurement': 'Units',
        'targetPrice': 3000000.00,
        'deliveryLocation': 'Ahmedabad, Gujarat',
        'status': 'Open',
        'createdAtUtc': '2026-11-01T08:00:00Z',
      };

      final rfq = Rfq.fromJson(rfqJson);
      expect(rfq.id, 301);
      expect(rfq.rfqNumber, 'RFQ-20261101-0001');
      expect(rfq.quantity, 2.0);
      expect(rfq.status, RfqStatus.open);

      final quoteJson = <String, dynamic>{
        'id': 401,
        'rfqId': 301,
        'rfqNumber': 'RFQ-20261101-0001',
        'quotationNumber': 'QTN-20261101-0001',
        'version': 1,
        'supplierMemberId': 42,
        'supplierName': 'Supplier Alice',
        'supplierCompanyName': 'Machinery Corp',
        'buyerMemberId': 10,
        'buyerName': 'Buyer John',
        'buyerCompanyName': 'Procurement Inc',
        'unitPrice': 1450000.00,
        'quantity': 2.0,
        'subtotal': 2900000.00,
        'taxRatePercent': 18.0,
        'taxAmount': 522000.00,
        'shippingCharges': 25000.00,
        'totalAmount': 3447000.00,
        'validUntilUtc': '2026-11-15T12:00:00Z',
        'estimatedDeliveryTime': '10 to 14 days',
        'status': 'Accepted',
        'createdAtUtc': '2026-11-01T09:00:00Z',
        'isExpired': false,
      };

      final quote = Quotation.fromJson(quoteJson);
      expect(quote.id, 401);
      expect(quote.quotationNumber, 'QTN-20261101-0001');
      expect(quote.totalAmount, 3447000.00);
      expect(quote.status, QuotationStatus.accepted);
      expect(quote.status == QuotationStatus.accepted, isTrue);
    });

    test('G. Order Management Models: Simple Order Lifecycle & Completed Status', () {
      final orderJson = <String, dynamic>{
        'id': 501,
        'orderNumber': 'ORD-20261101-0001',
        'quotationId': 401,
        'quotationNumber': 'QTN-20261101-0001',
        'rfqId': 301,
        'rfqNumber': 'RFQ-20261101-0001',
        'productId': 101,
        'productName': 'CNC Vertical Lathe Machine',
        'buyerMemberId': 10,
        'buyerFullName': 'Buyer John',
        'buyerCompanyName': 'Procurement Inc',
        'supplierMemberId': 42,
        'supplierFullName': 'Supplier Alice',
        'supplierCompanyName': 'Machinery Corp',
        'quantity': 2.0,
        'unitOfMeasurement': 'Units',
        'unitPrice': 1450000.00,
        'subtotal': 2900000.00,
        'taxRatePercent': 18.0,
        'taxAmount': 522000.00,
        'shippingCharges': 25000.00,
        'totalAmount': 3447000.00,
        'deliveryAddress': 'Plot 42, GIDC Vatva, Ahmedabad',
        'status': 'Delivered',
        'isBuyer': true,
        'isSupplier': false,
        'createdAtUtc': '2026-11-01T10:00:00Z',
        'deliveredAtUtc': '2026-11-01T16:00:00Z',
        'statusHistory': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'orderId': 501,
            'previousStatus': null,
            'newStatus': 'PendingConfirmation',
            'changedByMemberId': 10,
            'changedByMemberName': 'Buyer John',
            'changedAtUtc': '2026-11-01T10:00:00Z',
            'remarks': 'Order placed',
          },
          <String, dynamic>{
            'id': 2,
            'orderId': 501,
            'previousStatus': 'PendingConfirmation',
            'newStatus': 'Confirmed',
            'changedByMemberId': 42,
            'changedByMemberName': 'Supplier Alice',
            'changedAtUtc': '2026-11-01T10:30:00Z',
            'remarks': 'Order confirmed',
          },
          <String, dynamic>{
            'id': 3,
            'orderId': 501,
            'previousStatus': 'Confirmed',
            'newStatus': 'Delivered',
            'changedByMemberId': 10,
            'changedByMemberName': 'Buyer John',
            'changedAtUtc': '2026-11-01T16:00:00Z',
            'remarks': 'Received and completed',
          },
        ],
      };

      final order = Order.fromJson(orderJson);
      expect(order.id, 501);
      expect(order.orderNumber, 'ORD-20261101-0001');
      expect(order.status, OrderStatus.delivered);
      expect(order.status.label, 'Completed');
      expect(order.statusHistory.length, 3);
      expect(order.statusHistory.last.newStatus, 'Delivered');
    });

    test('H. Notifications: Payload Parsing and Deep-Link Destination Mapping', () {
      final notifJson = <String, dynamic>{
        'id': 601,
        'recipientMemberId': 10,
        'actorMemberId': 42,
        'actorName': 'Supplier Alice',
        'actorCompanyName': 'Machinery Corp',
        'eventType': 'OrderDelivered',
        'title': 'Order Completed #ORD-20261101-0001',
        'message': 'Your order has been completed.',
        'referenceType': 'order',
        'referenceId': 501,
        'isRead': false,
        'createdAtUtc': '2026-11-01T16:01:00Z',
      };

      final notif = AppNotification.fromJson(notifJson);
      expect(notif.id, 601);
      expect(notif.eventType, 'OrderDelivered');
      expect(notif.referenceType, 'order');
      expect(notif.referenceId, 501);
      expect(notif.isRead, isFalse);

      // Deep link navigation rules check
      String resolveDeepLink(String? refType, int? refId, String? eventType) {
        final type = refType?.toLowerCase();
        if (type == 'connection') {
          return eventType == 'ConnectionRequestReceived' ? '/network?tab=1' : '/network?tab=0';
        } else if (type == 'inquiry') {
          return refId != null && refId > 0 ? '/inquiries/$refId' : '/inquiries';
        } else if (type == 'product') {
          return refId != null && refId > 0 ? '/products/$refId' : '/products';
        } else if (type == 'rfq') {
          return refId != null && refId > 0 ? '/rfqs/$refId' : '/rfqs';
        } else if (type == 'order') {
          return refId != null && refId > 0 ? '/orders/$refId' : '/orders';
        } else if (type == 'verification') {
          return '/profile/verification';
        }
        return '/notifications';
      }

      expect(resolveDeepLink('order', 501, 'OrderDelivered'), '/orders/501');
      expect(resolveDeepLink('rfq', 301, 'QuotationAccepted'), '/rfqs/301');
      expect(resolveDeepLink('product', 101, 'ProductViewed'), '/products/101');
      expect(resolveDeepLink('connection', 201, 'ConnectionRequestReceived'), '/network?tab=1');
      expect(resolveDeepLink('verification', null, 'VerificationApproved'), '/profile/verification');
    });
  });
}
