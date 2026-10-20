import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/connections/models/connection_models.dart';
import 'package:connexa/features/connections/providers/connection_provider.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(connectionsNotifierProvider.notifier)
            .setActiveTab(_tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionsNotifierProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(connectionsNotifierProvider.notifier).setSearch(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref
        .read(connectionsNotifierProvider.notifier)
        .setSearch('', immediate: true);
  }

  Future<void> _confirmRemoveConnection(ConnectedMemberItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Remove Connection'),
          content: Text(
            'Are you sure you want to remove your connection with ${item.companyName}? You will no longer be linked in each other\'s network.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Remove',
              height: 38,
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final bool success = await ref
        .read(connectionsNotifierProvider.notifier)
        .removeConnection(item.memberId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed connection with ${item.companyName}.'),
          backgroundColor: AppColors.textPrimary,
        ),
      );
    } else {
      final String err =
          ref.read(connectionsNotifierProvider).errorMessage ??
          'Failed to remove connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleAcceptRequest(ConnectionRequestItem item) async {
    final bool success = await ref
        .read(connectionsNotifierProvider.notifier)
        .acceptRequest(item.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected with ${item.companyName}!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final String err =
          ref.read(connectionsNotifierProvider).errorMessage ??
          'Failed to accept request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleRejectRequest(ConnectionRequestItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Decline Request'),
          content: Text(
            'Decline the connection request from ${item.companyName}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx(ctx)).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Decline',
              height: 38,
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(dialogCtx(ctx)).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final bool success = await ref
        .read(connectionsNotifierProvider.notifier)
        .rejectRequest(item.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Declined request from ${item.companyName}.')),
      );
    } else {
      final String err =
          ref.read(connectionsNotifierProvider).errorMessage ??
          'Failed to reject request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  BuildContext dialogCtx(BuildContext ctx) => ctx;

  Future<void> _handleCancelRequest(ConnectionRequestItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: Text(
            'Cancel your pending connection request to ${item.companyName}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Request'),
            ),
            AppButton(
              text: 'Cancel Request',
              height: 38,
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final bool success = await ref
        .read(connectionsNotifierProvider.notifier)
        .cancelRequest(item.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request to ${item.companyName}.')),
      );
    } else {
      final String err =
          ref.read(connectionsNotifierProvider).errorMessage ??
          'Failed to cancel request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ConnectionsState state = ref.watch(connectionsNotifierProvider);
    final ConnectionsNotifier notifier = ref.read(
      connectionsNotifierProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Network'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Business Directory',
            onPressed: () => context.push('/directory'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Connections'),
                  if (state.summary.totalConnected > 0) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge.primary(
                      label: state.summary.totalConnected.toString(),
                      isPill: true,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Received'),
                  if (state.summary.receivedPendingCount > 0) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge.secondary(
                      label: state.summary.receivedPendingCount.toString(),
                      isPill: true,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Sent'),
                  if (state.summary.sentPendingCount > 0) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge.neutral(
                      label: state.summary.sentPendingCount.toString(),
                      isPill: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildConnectionsTab(state, notifier),
              _buildReceivedTab(state, notifier),
              _buildSentTab(state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionsTab(
    ConnectionsState state,
    ConnectionsNotifier notifier,
  ) {
    return RefreshIndicator(
      onRefresh: () => notifier.loadConnections(page: 1),
      child: Column(
        children: <Widget>[
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search connections by name, company, or industry...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Content
          Expanded(child: _buildConnectionsContent(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildConnectionsContent(
    ConnectionsState state,
    ConnectionsNotifier notifier,
  ) {
    if (state.isLoadingConnections) {
      return const Center(
        child: AppLoadingIndicator(message: 'Loading your business network...'),
      );
    }

    if (state.errorMessage != null && state.connections.isEmpty) {
      return Center(
        child: AppErrorState(
          title: 'Unable to Load Connections',
          description: state.errorMessage!,
          onRetry: () => notifier.loadConnections(),
        ),
      );
    }

    if (state.connections.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'No Connections Found',
          description: state.searchQuery.isNotEmpty
              ? 'No connections match "${state.searchQuery}".'
              : 'You haven\'t formed any business connections yet. Browse the Business Directory to connect with verified partners.',
          actionLabel: 'Discover Businesses',
          onAction: () => context.push('/directory'),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: state.connections.length,
      itemBuilder: (BuildContext context, int index) {
        final ConnectedMemberItem item = state.connections[index];
        return _buildConnectedMemberCard(context, item);
      },
    );
  }

  Widget _buildConnectedMemberCard(
    BuildContext context,
    ConnectedMemberItem item,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    item.companyName.isNotEmpty
                        ? item.companyName.substring(0, 1).toUpperCase()
                        : 'B',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.companyName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.fullName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const AppBadge.success(
                label: 'Connected',
                icon: Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: AppColors.onSuccessContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Business Details
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppBadge.primary(label: item.businessType),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item.displayLocation,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Since ${item.connectedSinceUtc.day}/${item.connectedSinceUtc.month}/${item.connectedSinceUtc.year}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),

          // Action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              AppButton.text(
                text: 'Remove Connection',
                leadingIcon: const Icon(
                  Icons.person_remove_outlined,
                  size: 16,
                  color: AppColors.error,
                ),
                foregroundColor: AppColors.error,
                height: 36,
                onPressed: () => _confirmRemoveConnection(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(
    ConnectionsState state,
    ConnectionsNotifier notifier,
  ) {
    if (state.isLoadingReceived) {
      return const Center(
        child: AppLoadingIndicator(message: 'Loading received requests...'),
      );
    }

    if (state.errorMessage != null && state.receivedRequests.isEmpty) {
      return Center(
        child: AppErrorState(
          title: 'Unable to Load Requests',
          description: state.errorMessage!,
          onRetry: () => notifier.loadReceivedRequests(),
        ),
      );
    }

    if (state.receivedRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.loadReceivedRequests(page: 1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            const AppEmptyState(
              title: 'No Pending Requests',
              description:
                  'You do not have any incoming connection requests waiting for review.',
              icon: Icons.mark_email_read_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadReceivedRequests(page: 1),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: state.receivedRequests.length,
        itemBuilder: (BuildContext context, int index) {
          final ConnectionRequestItem item = state.receivedRequests[index];
          final bool isItemBusy =
              state.isProcessingAction && state.processingId == item.id;

          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.secondaryContainer,
                      child: Text(
                        item.companyName.isNotEmpty
                            ? item.companyName.substring(0, 1).toUpperCase()
                            : 'M',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.companyName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.fullName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.businessType} • ${item.displayLocation}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (item.note != null &&
                    item.note!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            item.note!.trim(),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton.secondary(
                        text: 'Decline',
                        onPressed: isItemBusy
                            ? null
                            : () => _handleRejectRequest(item),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Accept',
                        isLoading: isItemBusy,
                        leadingIcon: const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                        ),
                        onPressed: isItemBusy
                            ? null
                            : () => _handleAcceptRequest(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentTab(ConnectionsState state, ConnectionsNotifier notifier) {
    if (state.isLoadingSent) {
      return const Center(
        child: AppLoadingIndicator(message: 'Loading sent requests...'),
      );
    }

    if (state.errorMessage != null && state.sentRequests.isEmpty) {
      return Center(
        child: AppErrorState(
          title: 'Unable to Load Sent Requests',
          description: state.errorMessage!,
          onRetry: () => notifier.loadSentRequests(),
        ),
      );
    }

    if (state.sentRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.loadSentRequests(page: 1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            AppEmptyState(
              title: 'No Outgoing Requests',
              description: 'You have not sent any pending connection requests.',
              actionLabel: 'Browse Directory',
              icon: Icons.send_outlined,
              onAction: () => context.push('/directory'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadSentRequests(page: 1),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: state.sentRequests.length,
        itemBuilder: (BuildContext context, int index) {
          final ConnectionRequestItem item = state.sentRequests[index];
          final bool isItemBusy =
              state.isProcessingAction && state.processingId == item.id;

          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        item.companyName.isNotEmpty
                            ? item.companyName.substring(0, 1).toUpperCase()
                            : 'M',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.companyName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.fullName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.businessType} • ${item.displayLocation}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppBadge.warning(label: 'Pending'),
                  ],
                ),

                if (item.note != null &&
                    item.note!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Note: "${item.note!.trim()}"',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    AppButton.secondary(
                      text: 'Cancel Request',
                      height: 38,
                      isLoading: isItemBusy,
                      leadingIcon: const Icon(Icons.cancel_outlined, size: 16),
                      onPressed: isItemBusy
                          ? null
                          : () => _handleCancelRequest(item),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
