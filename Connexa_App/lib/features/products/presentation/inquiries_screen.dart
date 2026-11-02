import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/core/widgets/responsive_layout.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/providers/product_provider.dart';

/// Screen allowing members to manage both Received and Sent product inquiries.
/// Includes search, status filtering, responsive cards, and navigation to details.
class InquiriesScreen extends ConsumerStatefulWidget {
  const InquiriesScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends ConsumerState<InquiriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  static const List<String> _statusFilters = <String>[
    'All',
    'Pending',
    'Read',
    'Responded',
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
    ref.invalidate(recentInquiriesProvider);
    ref.invalidate(sentInquiriesProvider);
  }

  List<ProductInquiry> _filterInquiries(List<ProductInquiry> inquiries) {
    final String query = _searchController.text.trim().toLowerCase();

    return inquiries.where((ProductInquiry item) {
      // Status filter
      if (_selectedStatus != 'All') {
        if (item.status.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      // Search query
      if (query.isNotEmpty) {
        final bool prodMatch = item.productName.toLowerCase().contains(query);
        final bool subjMatch = item.subject.toLowerCase().contains(query);
        final bool msgMatch = item.message.toLowerCase().contains(query);
        final bool senderMatch =
            item.senderName.toLowerCase().contains(query) ||
            item.senderCompanyName.toLowerCase().contains(query);
        final bool recipientMatch = (item.recipientCompanyName ?? '')
            .toLowerCase()
            .contains(query);

        return prodMatch ||
            subjMatch ||
            msgMatch ||
            senderMatch ||
            recipientMatch;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProductInquiry>> receivedAsync = ref.watch(
      recentInquiriesProvider,
    );
    final AsyncValue<List<ProductInquiry>> sentAsync = ref.watch(
      sentInquiriesProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(114),
        child: AppBar(
          backgroundColor: const Color(0xFF062747), // Connexa Deep Navy
          elevation: 0,
          leading: IconButton(
            key: const Key('inquiriesBackButton'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text(
                'Product Inquiries',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Manage trade leads and buyer requests',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              key: const Key('inquiriesRefreshButton'),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Refresh',
              onPressed: _handleRefresh,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF38BDF8),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            tabs: <Widget>[
              Tab(
                key: const Key('receivedInquiriesTab'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.move_to_inbox_rounded, size: 14),
                    const SizedBox(width: 4),
                    const Text('Received'),
                    if (receivedAsync.valueOrNull != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _buildCountBadge(receivedAsync.valueOrNull!.length),
                    ],
                  ],
                ),
              ),
              Tab(
                key: const Key('sentInquiriesTab'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.outbox_rounded, size: 14),
                    const SizedBox(width: 4),
                    const Text('Sent'),
                    if (sentAsync.valueOrNull != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _buildCountBadge(sentAsync.valueOrNull!.length),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              // Search & Filter Header
              _buildSearchAndFilters(),
              const SizedBox(height: AppSpacing.sm),
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    // Tab 0: Received Inquiries (Product Owner)
                    _buildInquiriesList(
                      asyncValue: receivedAsync,
                      isReceived: true,
                    ),
                    // Tab 1: Sent Inquiries (Buyer)
                    _buildInquiriesList(
                      asyncValue: sentAsync,
                      isReceived: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? const Color(0xFF2563EB) : Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Search Input Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            key: const Key('inquiriesSearchField'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by company, product or message...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statusFilters.map((String status) {
              final bool isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  key: Key('statusFilter_${status.toLowerCase()}'),
                  label: Text(status),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInquiriesList({
    required AsyncValue<List<ProductInquiry>> asyncValue,
    required bool isReceived,
  }) {
    return asyncValue.when(
      loading: () => const Center(
        child: AppLoadingIndicator(message: 'Loading inquiries...'),
      ),
      error: (Object error, _) => AppErrorState(
        title: 'Unable to Load Inquiries',
        description: error.toString(),
        onRetry: _handleRefresh,
      ),
      data: (List<ProductInquiry> all) {
        final List<ProductInquiry> items = _filterInquiries(all);

        if (items.isEmpty) {
          if (all.isEmpty) {
            return _buildEmptyState(isReceived: isReceived);
          }
          return _buildNoFilterMatchState();
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: AppSpacing.xxl),
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final ProductInquiry inquiry = items[index];
              return _InquiryCard(
                key: Key('inquiryCard_${inquiry.id}'),
                inquiry: inquiry,
                isReceived: isReceived,
                onTap: () {
                  context.push('/inquiries/${inquiry.id}', extra: inquiry);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required bool isReceived}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReceived ? Icons.move_to_inbox_rounded : Icons.outbox_rounded,
                color: const Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isReceived
                  ? 'No received inquiries yet'
                  : 'No inquiries sent yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isReceived
                  ? 'When buyers send inquiries regarding your products, they will appear here.'
                  : 'Explore products from fellow Connexa businesses and submit your trade inquiries.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (!isReceived) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                key: const Key('exploreProductsButton'),
                onPressed: () => context.go('/products'),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const Text('Explore Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterMatchState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF94A3B8),
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No matching inquiries',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search query or status filter.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedStatus = 'All';
                });
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A responsive, information-rich card presenting an inquiry item in the list.
class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    super.key,
    required this.inquiry,
    required this.isReceived,
    required this.onTap,
  });

  final ProductInquiry inquiry;
  final bool isReceived;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String otherPartyName = isReceived
        ? (inquiry.senderCompanyName.isNotEmpty
              ? inquiry.senderCompanyName
              : inquiry.senderName)
        : (inquiry.recipientCompanyName?.isNotEmpty == true
              ? inquiry.recipientCompanyName!
              : 'Product Owner');

    final String partyRole = isReceived ? 'Buyer' : 'Recipient';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Party info and Status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isReceived
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        otherPartyName.isNotEmpty
                            ? otherPartyName[0].toUpperCase()
                            : 'C',
                        style: TextStyle(
                          color: isReceived
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Name and role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          otherPartyName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Text(
                              partyRole,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isReceived &&
                                inquiry.senderName.isNotEmpty) ...<Widget>[
                              const Text(
                                ' • ',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                              Expanded(
                                child: Text(
                                  inquiry.senderName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStatusBadge(inquiry.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: AppSpacing.sm),

              // Product Info & Date
              Row(
                children: <Widget>[
                  // Thumbnail
                  _buildProductThumbnail(inquiry.productThumbnailUrl),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          inquiry.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(inquiry.createdAtUtc),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quantity badge if available
                  if (inquiry.quantityRequirement != null &&
                      inquiry.quantityRequirement!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            inquiry.quantityRequirement!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Inquiry Message Snippet
              Text(
                inquiry.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),

              // Response snippet if present
              if (inquiry.responseMessage != null &&
                  inquiry.responseMessage!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.reply_rounded,
                        size: 14,
                        color: Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Response: ${inquiry.responseMessage}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Bottom row: authorized contact hint or details tap
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (isReceived &&
                      (inquiry.contactPhone != null ||
                          inquiry.contactEmail != null))
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget>[
                          Icon(
                            Icons.verified_user_outlined,
                            size: 12,
                            color: Color(0xFF0D9488),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Direct contact authorized',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0D9488),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      final String firstUrl = url.split(RegExp(r'[,;]'))[0].trim();
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          firstUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext ctx, Object err, _) =>
              _buildThumbnailFallback(),
        ),
      );
    }
    return _buildThumbnailFallback();
  }

  Widget _buildThumbnailFallback() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 18,
        color: Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return switch (status.toLowerCase()) {
      'responded' => const AppBadge.success(
        label: 'Responded',
        isPill: true,
        fontSize: 10,
      ),
      'read' => const AppBadge.info(label: 'Read', isPill: true, fontSize: 10),
      _ => const AppBadge.warning(label: 'Pending', isPill: true, fontSize: 10),
    };
  }

  String _formatDate(DateTime dt) {
    final DateTime local = dt.toLocal();
    final List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}
