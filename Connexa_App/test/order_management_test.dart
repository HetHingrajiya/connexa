import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/features/orders/models/order_models.dart';
import 'package:connexa/features/orders/presentation/order_dialogs.dart';
import 'package:connexa/features/orders/presentation/order_details_screen.dart';
import 'package:connexa/features/orders/presentation/orders_screen.dart';
import 'package:connexa/features/orders/providers/order_provider.dart';

void main() {
  group('Order Models Unit Tests', () {
    test('OrderStatus.fromString parses all status values correctly', () {
      expect(OrderStatus.fromString('pendingconfirmation'), OrderStatus.pendingConfirmation);
      expect(OrderStatus.fromString('Confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('PROCESSING'), OrderStatus.processing);
      expect(OrderStatus.fromString('shipped'), OrderStatus.shipped);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('rejected'), OrderStatus.rejected);
      expect(OrderStatus.fromString('unknown_status'), OrderStatus.pendingConfirmation);
    });

    test('OrderStatus labels and styling properties are non-empty', () {
      for (final status in OrderStatus.values) {
        expect(status.label.isNotEmpty, isTrue);
        expect(status.color, isNotNull);
        expect(status.backgroundColor, isNotNull);
        expect(status.icon, isNotNull);
      }
    });

    test('Order serialization roundtrip with status history and tracking', () {
      final now = DateTime.utc(2026, 11, 1, 12, 0, 0);
      final history = OrderStatusHistory(
        id: 1,
        orderId: 10,
        previousStatus: null,
        newStatus: 'PendingConfirmation',
        changedByMemberId: 5,
        changedByMemberName: 'Alice Buyer',
        changedByCompanyName: 'Acme Corp',
        changedAtUtc: now,
        remarks: 'Order initiated from accepted quotation.',
      );

      final order = Order(
        id: 10,
        orderNumber: 'ORD-20261101-0001',
        quotationId: 25,
        quotationNumber: 'QTN-20261101-0001',
        rfqId: 50,
        rfqNumber: 'RFQ-20261101-0001',
        productId: 100,
        productName: 'Heavy Duty Industrial Pump',
        buyerMemberId: 5,
        buyerFullName: 'Alice Buyer',
        buyerCompanyName: 'Acme Corp',
        supplierMemberId: 8,
        supplierFullName: 'Bob Supplier',
        supplierCompanyName: 'Mega Machinery Ltd',
        quantity: 2.0,
        unitOfMeasurement: 'Set',
        unitPrice: 25000.0,
        subtotal: 50000.0,
        taxRatePercent: 18.0,
        taxAmount: 9000.0,
        shippingCharges: 1500.0,
        totalAmount: 60500.0,
        deliveryAddress: 'Sector 4, Industrial Area, Pune 411018',
        expectedDeliveryDateUtc: now.add(const Duration(days: 7)),
        carrierName: 'Blue Dart Logistics',
        trackingNumber: 'BD-88234102',
        trackingUrl: 'https://track.bluedart.com/BD-88234102',
        shippedAtUtc: now.add(const Duration(days: 2)),
        status: OrderStatus.shipped,
        createdAtUtc: now,
        statusHistory: [history],
        isBuyer: true,
        isSupplier: false,
      );

      final json = order.toJson();
      expect(json['orderNumber'], 'ORD-20261101-0001');
      expect(json['totalAmount'], 60500.0);
      expect(json['carrierName'], 'Blue Dart Logistics');

      final deserialized = Order.fromJson(json);
      expect(deserialized.id, 10);
      expect(deserialized.orderNumber, 'ORD-20261101-0001');
      expect(deserialized.status, OrderStatus.shipped);
      expect(deserialized.statusHistory.length, 1);
      expect(deserialized.statusHistory.first.newStatus, 'PendingConfirmation');
      expect(deserialized.statusHistory.first.changedByCompanyName, 'Acme Corp');
    });

    test('OrderListResponse handles both List and Map payloads', () {
      final itemMap = {
        'id': 1,
        'orderNumber': 'ORD-001',
        'quotationId': 2,
        'quotationNumber': 'QTN-001',
        'rfqId': 3,
        'rfqNumber': 'RFQ-001',
        'productId': 4,
        'productName': 'Pipes',
        'buyerMemberId': 5,
        'buyerFullName': 'Buyer A',
        'buyerCompanyName': 'A Corp',
        'supplierMemberId': 6,
        'supplierFullName': 'Supplier B',
        'supplierCompanyName': 'B Corp',
        'quantity': 10.0,
        'unitOfMeasurement': 'Units',
        'unitPrice': 100.0,
        'subtotal': 1000.0,
        'taxRatePercent': 18.0,
        'taxAmount': 180.0,
        'shippingCharges': 50.0,
        'totalAmount': 1230.0,
        'deliveryAddress': 'Address 1',
        'status': 'Confirmed',
        'createdAtUtc': '2026-11-01T12:00:00Z',
      };

      // Case 1: Raw List
      final fromList = OrderListResponse.fromResponseData([itemMap], 1);
      expect(fromList.items.length, 1);
      expect(fromList.totalCount, 1);
      expect(fromList.items.first.status, OrderStatus.confirmed);

      // Case 2: Paginated Map
      final fromMap = OrderListResponse.fromResponseData({
        'items': [itemMap],
        'totalCount': 10,
        'page': 2,
        'pageSize': 1,
        'totalPages': 10,
      });
      expect(fromMap.items.length, 1);
      expect(fromMap.totalCount, 10);
      expect(fromMap.page, 2);
    });
  });

  group('Order Dialogs Widget Tests', () {
    testWidgets('ShipOrderDialog validates required carrier and tracking fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShipOrderDialog(orderNumber: 'ORD-20261101-0001'),
          ),
        ),
      );

      expect(find.text('Ship Order'), findsOneWidget);
      expect(find.byKey(const Key('shipCarrierField')), findsOneWidget);
      expect(find.byKey(const Key('shipTrackingField')), findsOneWidget);

      // Attempt to submit empty
      await tester.tap(find.byKey(const Key('submitShipOrderButton')));
      await tester.pumpAndSettle();

      expect(find.text('Carrier name is required'), findsOneWidget);

      // Fill in fields
      await tester.enterText(find.byKey(const Key('shipCarrierField')), 'FedEx Freight');
      await tester.enterText(find.byKey(const Key('shipTrackingField')), 'FX-998822');
      await tester.enterText(find.byKey(const Key('shipUrlField')), 'https://fedex.com/track/FX-998822');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submitShipOrderButton')));
      await tester.pumpAndSettle();

      // Dialog should close after valid submission
      expect(find.text('Carrier name is required'), findsNothing);
    });

    testWidgets('OrderReasonDialog enforces minimum characters for reason', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderReasonDialog(
              title: 'Cancel Order',
              hintText: 'Enter cancellation reason',
              actionButtonText: 'Cancel Order',
              isDestructive: true,
            ),
          ),
        ),
      );

      expect(find.text('Cancel Order'), findsNWidgets(2)); // Title and button

      // Submit empty
      await tester.tap(find.byKey(const Key('submitOrderReasonButton')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a reason'), findsOneWidget);

      // Submit short (< 5 chars)
      await tester.enterText(find.byKey(const Key('orderReasonField')), 'bad');
      await tester.tap(find.byKey(const Key('submitOrderReasonButton')));
      await tester.pumpAndSettle();
      expect(find.text('Reason must be at least 5 characters'), findsOneWidget);

      // Submit valid
      await tester.enterText(find.byKey(const Key('orderReasonField')), 'Customer changed requirements.');
      await tester.tap(find.byKey(const Key('submitOrderReasonButton')));
      await tester.pumpAndSettle();
      expect(find.text('Reason must be at least 5 characters'), findsNothing);
    });
  });

  group('Orders Screen Widget Tests', () {
    testWidgets('OrdersScreen renders tabs, filter chips and empty state cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myOrdersProvider.overrideWith(() => MockMyOrdersNotifier(
              const OrderListResponse(items: [], totalCount: 0, page: 1, pageSize: 10, totalPages: 0),
            )),
            receivedOrdersProvider.overrideWith(() => MockReceivedOrdersNotifier(
              const OrderListResponse(items: [], totalCount: 0, page: 1, pageSize: 10, totalPages: 0),
            )),
          ],
          child: const MaterialApp(
            home: OrdersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('B2B Orders'), findsOneWidget);
      expect(find.byKey(const Key('myOrdersTab')), findsOneWidget);
      expect(find.byKey(const Key('receivedOrdersTab')), findsOneWidget);
      expect(find.byKey(const Key('orderSearchField')), findsOneWidget);
      expect(find.byKey(const Key('filterChip_All')), findsOneWidget);
      expect(find.byKey(const Key('filterChip_PendingConfirmation')), findsOneWidget);

      // Empty state
      expect(find.text('You haven\'t placed any orders yet.'), findsOneWidget);

      // Switch to Received Orders tab
      await tester.tap(find.byKey(const Key('receivedOrdersTab')));
      await tester.pumpAndSettle();
      expect(find.text('No orders received from buyers yet.'), findsOneWidget);
    });
  });

  group('Order Details Screen Widget Tests', () {
    testWidgets('OrderDetailsScreen displays financial breakdown, timeline, and supplier actions', (WidgetTester tester) async {
      final now = DateTime.utc(2026, 11, 1, 10, 0, 0);
      final testOrder = Order(
        id: 42,
        orderNumber: 'ORD-20261101-0042',
        quotationId: 10,
        quotationNumber: 'QTN-0010',
        rfqId: 5,
        rfqNumber: 'RFQ-0005',
        productId: 12,
        productName: 'Galvanized Sheet Metal',
        buyerMemberId: 100,
        buyerFullName: 'David Buyer',
        buyerCompanyName: 'Apex Builders Ltd',
        supplierMemberId: 200,
        supplierFullName: 'Sam Supplier',
        supplierCompanyName: 'National Steel Corp',
        quantity: 50.0,
        unitOfMeasurement: 'Tons',
        unitPrice: 1200.0,
        subtotal: 60000.0,
        taxRatePercent: 18.0,
        taxAmount: 10800.0,
        shippingCharges: 2500.0,
        totalAmount: 73300.0,
        deliveryAddress: 'Plot 88, Sector 12, MIDC Navi Mumbai',
        status: OrderStatus.pendingConfirmation,
        createdAtUtc: now,
        termsAndConditionsSnapshot: 'Payment via NEFT within 15 days of dispatch.',
        statusHistory: [
          OrderStatusHistory(
            id: 1,
            orderId: 42,
            previousStatus: null,
            newStatus: 'PendingConfirmation',
            changedByMemberId: 100,
            changedByMemberName: 'David Buyer',
            changedByCompanyName: 'Apex Builders Ltd',
            changedAtUtc: now,
            remarks: 'Initial order submission from accepted quote.',
          ),
        ],
        isBuyer: false,
        isSupplier: true, // Viewer is Supplier!
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderDetailsProvider(42).overrideWith((ref) => Future.value(testOrder)),
          ],
          child: const MaterialApp(
            home: OrderDetailsScreen(orderId: 42),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Overview & Product Details
      expect(find.text('ORD-20261101-0042'), findsWidgets);
      expect(find.text('Galvanized Sheet Metal'), findsOneWidget);
      expect(find.text('Apex Builders Ltd'), findsWidgets);
      expect(find.text('National Steel Corp'), findsWidgets);

      // Financial breakdown
      expect(find.text('Commercial Terms & Payment Breakdown'), findsOneWidget);
      expect(find.text('₹73300.00'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);

      // Audit Timeline
      expect(find.text('Order Audit & Status Timeline'), findsOneWidget);
      expect(find.text('Initial order submission from accepted quote.'), findsOneWidget);

      // Supplier Actions for PendingConfirmation
      expect(find.byKey(const Key('confirmOrderButton')), findsOneWidget);
      expect(find.byKey(const Key('rejectOrderButton')), findsOneWidget);
    });

    testWidgets('OrderDetailsScreen displays buyer cancel action for pending orders', (WidgetTester tester) async {
      final now = DateTime.utc(2026, 11, 1, 10, 0, 0);
      final testOrder = Order(
        id: 43,
        orderNumber: 'ORD-20261101-0043',
        quotationId: 11,
        quotationNumber: 'QTN-0011',
        rfqId: 6,
        rfqNumber: 'RFQ-0006',
        productId: 14,
        productName: 'Commercial Copper Wire',
        buyerMemberId: 100,
        buyerFullName: 'David Buyer',
        buyerCompanyName: 'Apex Builders Ltd',
        supplierMemberId: 200,
        supplierFullName: 'Sam Supplier',
        supplierCompanyName: 'National Steel Corp',
        quantity: 10.0,
        unitOfMeasurement: 'Spools',
        unitPrice: 500.0,
        subtotal: 5000.0,
        taxRatePercent: 18.0,
        taxAmount: 900.0,
        shippingCharges: 100.0,
        totalAmount: 6000.0,
        deliveryAddress: 'Plot 88, Sector 12, MIDC Navi Mumbai',
        status: OrderStatus.confirmed,
        createdAtUtc: now,
        isBuyer: true, // Viewer is Buyer!
        isSupplier: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderDetailsProvider(43).overrideWith((ref) => Future.value(testOrder)),
          ],
          child: const MaterialApp(
            home: OrderDetailsScreen(orderId: 43),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buyer Actions for Confirmed order include both Cancel and Mark Received/Completed
      expect(find.byKey(const Key('buyerCancelOrderButton')), findsOneWidget);
      expect(find.byKey(const Key('buyerConfirmReceiptButton')), findsOneWidget);
    });

    testWidgets('OrderDetailsScreen displays completed banner when status is Delivered', (WidgetTester tester) async {
      final now = DateTime.utc(2026, 11, 1, 10, 0, 0);
      final testOrder = Order(
        id: 44,
        orderNumber: 'ORD-20261101-0044',
        quotationId: 12,
        quotationNumber: 'QTN-0012',
        rfqId: 7,
        rfqNumber: 'RFQ-0007',
        productId: 15,
        productName: 'Hydraulic Valves',
        buyerMemberId: 100,
        buyerFullName: 'David Buyer',
        buyerCompanyName: 'Apex Builders Ltd',
        supplierMemberId: 200,
        supplierFullName: 'Sam Supplier',
        supplierCompanyName: 'National Steel Corp',
        quantity: 5.0,
        unitOfMeasurement: 'Pieces',
        unitPrice: 2000.0,
        subtotal: 10000.0,
        taxRatePercent: 18.0,
        taxAmount: 1800.0,
        shippingCharges: 200.0,
        totalAmount: 12000.0,
        deliveryAddress: 'Plot 88, Sector 12, MIDC Navi Mumbai',
        status: OrderStatus.delivered,
        createdAtUtc: now,
        deliveredAtUtc: now.add(const Duration(days: 3)),
        statusHistory: [
          OrderStatusHistory(
            id: 2,
            orderId: 44,
            previousStatus: 'Confirmed',
            newStatus: 'Delivered',
            changedByMemberId: 100,
            changedByMemberName: 'David Buyer',
            changedByCompanyName: 'Apex Builders Ltd',
            changedAtUtc: now.add(const Duration(days: 3)),
            remarks: 'Client received items and confirmed completion.',
          ),
        ],
        isBuyer: true,
        isSupplier: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderDetailsProvider(44).overrideWith((ref) => Future.value(testOrder)),
          ],
          child: const MaterialApp(
            home: OrderDetailsScreen(orderId: 44),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Order Completed'), findsWidgets);
      expect(find.text('Client received items and confirmed completion.'), findsOneWidget);
    });
  });
}

class MockMyOrdersNotifier extends MyOrdersNotifier {
  MockMyOrdersNotifier(this._initial);
  final OrderListResponse _initial;

  @override
  Future<OrderListResponse> build() async => _initial;
}

class MockReceivedOrdersNotifier extends ReceivedOrdersNotifier {
  MockReceivedOrdersNotifier(this._initial);
  final OrderListResponse _initial;

  @override
  Future<OrderListResponse> build() async => _initial;
}

