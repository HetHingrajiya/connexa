import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/providers/rfq_provider.dart';

/// Screen managing both Sent RFQs (as Buyer) and Received RFQs (as Supplier).
class RfqsScreen extends ConsumerStatefulWidget {
  const RfqsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<RfqsScreen> createState() => _RfqsScreenState();
}

class _RfqsScreenState extends ConsumerState<RfqsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  static const List<String> _statusFilters = <String>[
    'All',
    'Open',
    'QuotationReceived',
    'Closed',
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
    ref.invalidate(myRfqsProvider);
    ref.invalidate(receivedRfqsProvider);
  }

  List<Rfq> _filterRfqs(List<Rfq> rfqs) {
    final String query = _searchController.text.trim().toLowerCase();

    return rfqs.where((Rfq item) {
      if (_selectedStatus != 'All') {
        if (item.status.name.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final bool numberMatch = item.rfqNumber.toLowerCase().contains(query);
        final bool prodMatch = item.productName.toLowerCase().contains(query);
        final bool buyerMatch = item.buyerCompanyName.toLowerCase().contains(query);
        final bool supplierMatch = item.supplierCompanyName.toLowerCase().contains(query);
        final bool locationMatch = item.deliveryLocation.toLowerCase().contains(query);
        return numberMatch || prodMatch || buyerMatch || supplierMatch || locationMatch;
      }

      return true;
    }).toList();
  }

  Widget _buildStatusBadge(RfqStatus status) {
    switch (status) {
      case RfqStatus.open:
        return const AppBadge(
          label: 'Open',
          variant: AppBadgeVariant.primary,
        );
      case RfqStatus.quotationReceived:
        return const AppBadge(
          label: 'Quote Received',
          variant: AppBadgeVariant.secondary,
        );
      case RfqStatus.closed:
        return const AppBadge(
          label: 'Closed / Accepted',
          variant: AppBadgeVariant.success,
        );
      case RfqStatus.cancelled:
        return const AppBadge(
          label: 'Cancelled',
          variant: AppBadgeVariant.neutral,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<RfqListResponse> myRfqsAsync = ref.watch(myRfqsProvider);
    final AsyncValue<RfqListResponse> receivedRfqsAsync =
        ref.watch(receivedRfqsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'RFQs & Quotations',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
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
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: <Widget>[
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.outbox_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text('My RFQs (Buyer)'),
                      if (myRfqsAsync.value?.items.isNotEmpty ?? false) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${myRfqsAsync.value!.items.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.inbox_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text('Received RFQs (Supplier)'),
                      if (receivedRfqsAsync.value?.items.isNotEmpty ?? false) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${receivedRfqsAsync.value!.items.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: <Widget>[
                TextField(
                  key: const Key('rfqSearchInput'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by RFQ #, product, company...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((String status) {
                      final bool isSelected = _selectedStatus == status;
                      String chipLabel = status;
                      if (status == 'QuotationReceived') chipLabel = 'Quote Received';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(chipLabel),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildRfqList(
                  asyncRfqs: myRfqsAsync,
                  isBuyerTab: true,
                  emptyTitle: 'No RFQs Created Yet',
                  emptySubtitle:
                      'Browse the product catalog and click "Request Quotation" to request bulk pricing from suppliers.',
                ),
                _buildRfqList(
                  asyncRfqs: receivedRfqsAsync,
                  isBuyerTab: false,
                  emptyTitle: 'No RFQs Received',
                  emptySubtitle:
                      'When buyers submit requests for quotation on your listed products, they will appear here.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRfqList({
    required AsyncValue<RfqListResponse> asyncRfqs,
    required bool isBuyerTab,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return asyncRfqs.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (Object err, StackTrace? stack) => Center(
        child: AppErrorState(
          title: 'Failed to load RFQs',
          description: err.toString().replaceFirst('Exception: ', ''),
          onRetry: _handleRefresh,
        ),
      ),
      data: (RfqListResponse response) {
        final List<Rfq> filtered = _filterRfqs(response.items);

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    isBuyerTab
                        ? Icons.request_page_outlined
                        : Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: filtered.length,
            itemBuilder: (BuildContext context, int index) {
              final Rfq rfq = filtered[index];
              return _buildRfqCard(rfq, isBuyerTab: isBuyerTab);
            },
          ),
        );
      },
    );
  }

  Widget _buildRfqCard(Rfq rfq, {required bool isBuyerTab}) {
    return Card(
      key: Key('rfqCard_${rfq.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/rfqs/${rfq.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Row: RFQ Number + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    rfq.rfqNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  _buildStatusBadge(rfq.status),
                ],
              ),
              const SizedBox(height: 10),

              // Product and Details Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          rfq.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBuyerTab
                              ? 'Supplier: ${rfq.supplierCompanyName}'
                              : 'Buyer: ${rfq.buyerCompanyName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Text(
                              'Qty: ${rfq.quantity.toStringAsFixed(0)} ${rfq.unitOfMeasurement}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (rfq.targetPrice != null) ...<Widget>[
                              const Text(' • ',
                                  style: TextStyle(color: AppColors.textMuted)),
                              Text(
                                'Target: ₹ ${rfq.targetPrice!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Quotation info snippet if available
              if (rfq.latestQuotation != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Quote v${rfq.latestQuotation!.version}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total: ₹ ${rfq.latestQuotation!.totalAmount.toStringAsFixed(2)} (${rfq.latestQuotation!.status.label})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),

              // Footer: Date and Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        rfq.deliveryLocation,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatRfqDate(rfq.createdAtUtc),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
