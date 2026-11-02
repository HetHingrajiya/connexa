import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';

class JobWorkOrdersScreen extends ConsumerStatefulWidget {
  const JobWorkOrdersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<JobWorkOrdersScreen> createState() =>
      _JobWorkOrdersScreenState();
}

class _JobWorkOrdersScreenState extends ConsumerState<JobWorkOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Work Orders'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const <Widget>[
            Tab(text: 'Placed Orders'),
            Tab(text: 'Received Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          _OrdersListView(role: 'buyer'),
          _OrdersListView(role: 'contractor'),
        ],
      ),
    );
  }
}

class _OrdersListView extends ConsumerWidget {
  const _OrdersListView({required this.role});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JobWorkOrdersState state = ref.watch(jobWorkOrdersProvider(role));

    return RefreshIndicator(
      onRefresh: () => ref.read(jobWorkOrdersProvider(role).notifier).loadOrders(),
      child: Column(
        children: <Widget>[
          // Status filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _buildStatusChip(ref, null, 'All'),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, JobWorkOrderStatus.confirmed, 'Confirmed'),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, JobWorkOrderStatus.processing, 'Processing'),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, JobWorkOrderStatus.completed, 'Completed'),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, JobWorkOrderStatus.cancelled, 'Cancelled'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: state.isLoading && state.orders.isEmpty
                ? const Center(
                    child: AppLoadingIndicator(message: 'Loading orders...'),
                  )
                : state.errorMessage != null && state.orders.isEmpty
                    ? AppErrorState(
                        title: 'Failed to load orders',
                        description: state.errorMessage!,
                        onRetry: () => ref
                            .read(jobWorkOrdersProvider(role).notifier)
                            .loadOrders(),
                      )
                    : state.orders.isEmpty
                        ? Center(
                            child: AppEmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: role == 'buyer'
                                  ? 'No Placed Job Work Orders'
                                  : 'No Received Job Work Orders',
                              description: role == 'buyer'
                                  ? 'When you accept contractor quotations, orders will appear here.'
                                  : 'When buyers accept your quotations, your orders will appear here.',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: state.orders.length,
                            separatorBuilder: (BuildContext context, int index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (BuildContext context, int index) {
                              final JobWorkOrder order = state.orders[index];
                              return _buildOrderCard(context, order);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      WidgetRef ref, JobWorkOrderStatus? status, String label) {
    final JobWorkOrdersState state = ref.watch(jobWorkOrdersProvider(role));
    final bool isSelected = state.statusFilter == status;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      onSelected: (_) {
        ref.read(jobWorkOrdersProvider(role).notifier).filterByStatus(status);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, JobWorkOrder order) {
    final String counterparty =
        role == 'buyer' ? order.contractorCompanyName : order.buyerCompanyName;
    final String counterpartyRole = role == 'buyer' ? 'Contractor' : 'Buyer';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/job-work-orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Order Number & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _buildOrderStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 6),

              // Job Title & Process
              Text(
                order.jobTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              Text(
                'Process: ${order.process} • Qty: ${order.quantity.toInt()} ${order.unitOfMeasurement}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),

              // Counterparty
              Row(
                children: <Widget>[
                  const Icon(Icons.business_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$counterpartyRole: $counterparty',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Total & Created Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    order.formattedTotal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Lead: ${order.leadTimeDays} days',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
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

  Widget _buildOrderStatusBadge(JobWorkOrderStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case JobWorkOrderStatus.confirmed:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
      case JobWorkOrderStatus.processing:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case JobWorkOrderStatus.completed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case JobWorkOrderStatus.cancelled:
      case JobWorkOrderStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case JobWorkOrderStatus.pendingConfirmation:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

