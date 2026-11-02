import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/orders/models/order_models.dart';
import 'package:connexa/features/orders/providers/order_provider.dart';

/// Screen displaying Buyer's Placed Orders and Supplier's Received Orders.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  static const List<String> _statusFilters = <String>[
    'All',
    'PendingConfirmation',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(myOrdersProvider);
    ref.invalidate(receivedOrdersProvider);
  }

  List<Order> _filterOrders(List<Order> orders) {
    final String query = _searchController.text.trim().toLowerCase();

    return orders.where((Order order) {
      if (_selectedStatus != 'All') {
        if (order.status.name.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final bool numberMatch = order.orderNumber.toLowerCase().contains(query);
        final bool prodMatch = order.productName.toLowerCase().contains(query);
        final bool buyerMatch = order.buyerCompanyName.toLowerCase().contains(query);
        final bool supplierMatch = order.supplierCompanyName.toLowerCase().contains(query);
        final bool trackingMatch = order.trackingNumber?.toLowerCase().contains(query) ?? false;
        return numberMatch || prodMatch || buyerMatch || supplierMatch || trackingMatch;
      }

      return true;
    }).toList();
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return const AppBadge(
          label: 'Pending Confirmation',
          variant: AppBadgeVariant.warning,
          icon: Icon(Icons.hourglass_top_rounded, size: 12),
        );
      case OrderStatus.confirmed:
        return const AppBadge(
          label: 'Confirmed',
          variant: AppBadgeVariant.info,
          icon: Icon(Icons.check_circle_outline_rounded, size: 12),
        );
      case OrderStatus.processing:
        return const AppBadge(
          label: 'Processing',
          variant: AppBadgeVariant.primary,
          icon: Icon(Icons.precision_manufacturing_outlined, size: 12),
        );
      case OrderStatus.shipped:
        return const AppBadge(
          label: 'Shipped',
          variant: AppBadgeVariant.secondary,
          icon: Icon(Icons.local_shipping_outlined, size: 12),
        );
      case OrderStatus.delivered:
        return const AppBadge(
          label: 'Completed',
          variant: AppBadgeVariant.success,
          icon: Icon(Icons.task_alt_rounded, size: 12),
        );
      case OrderStatus.cancelled:
        return const AppBadge(
          label: 'Cancelled',
          variant: AppBadgeVariant.neutral,
          icon: Icon(Icons.cancel_outlined, size: 12),
        );
      case OrderStatus.rejected:
        return const AppBadge(
          label: 'Rejected',
          variant: AppBadgeVariant.error,
          icon: Icon(Icons.highlight_off_rounded, size: 12),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OrderListResponse> myOrdersAsync = ref.watch(myOrdersProvider);
    final AsyncValue<OrderListResponse> receivedOrdersAsync =
        ref.watch(receivedOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'B2B Orders',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _handleRefresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: <Widget>[
                Tab(
                  key: const Key('myOrdersTab'),
                  text: 'My Orders (${myOrdersAsync.value?.totalCount ?? 0})',
                ),
                Tab(
                  key: const Key('receivedOrdersTab'),
                  text: 'Received Orders (${receivedOrdersAsync.value?.totalCount ?? 0})',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          // Search & Filter Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: <Widget>[
                // Search TextField
                TextField(
                  key: const Key('orderSearchField'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by order #, product, or company...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((String status) {
                      final bool isSelected = _selectedStatus == status;
                      String displayLabel = status;
                      if (status == 'PendingConfirmation') displayLabel = 'Pending Confirmation';
                      if (status == 'Delivered') displayLabel = 'Completed';

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          key: Key('filterChip_$status'),
                          label: Text(
                            displayLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceContainerLow,
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() => _selectedStatus = status);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tab View for Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                // Tab 0: My Orders (Buyer)
                _buildOrderList(
                  asyncValue: myOrdersAsync,
                  isBuyerTab: true,
                  emptyMessage: 'You haven\'t placed any orders yet.',
                ),

                // Tab 1: Received Orders (Supplier)
                _buildOrderList(
                  asyncValue: receivedOrdersAsync,
                  isBuyerTab: false,
                  emptyMessage: 'No orders received from buyers yet.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList({
    required AsyncValue<OrderListResponse> asyncValue,
    required bool isBuyerTab,
    required String emptyMessage,
  }) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace? stack) => Center(
        child: AppErrorState(
          title: 'Failed to load orders',
          description: error.toString().replaceFirst('Exception: ', ''),
          onRetry: _handleRefresh,
        ),
      ),
      data: (OrderListResponse response) {
        final List<Order> filtered = _filterOrders(response.items);

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                Center(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.receipt_long_outlined,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        emptyMessage,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Orders created from accepted quotations appear here.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: filtered.length,
            itemBuilder: (BuildContext context, int index) {
              final Order order = filtered[index];
              return _buildOrderCard(order, isBuyerTab);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, bool isBuyerTab) {
    final String counterpartyName =
        isBuyerTab ? order.supplierCompanyName : order.buyerCompanyName;
    final String counterpartyRole = isBuyerTab ? 'Supplier' : 'Buyer';

    return Card(
      key: Key('orderCard_${order.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Order #, Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 10),

              // Product Info & Qty
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          order.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.quantity.toStringAsFixed(0)} ${order.unitOfMeasurement} • ₹${order.unitPrice.toStringAsFixed(2)}/unit',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatOrderCurrency(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),

              // Footer: Counterparty, Delivery/Tracking
              Row(
                children: <Widget>[
                  Icon(
                    isBuyerTab ? Icons.store_outlined : Icons.business_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$counterpartyRole: $counterpartyName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.carrierName != null) ...<Widget>[
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      order.carrierName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ] else if (order.expectedDeliveryDateUtc != null) ...<Widget>[
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formatOrderDate(order.expectedDeliveryDateUtc),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
