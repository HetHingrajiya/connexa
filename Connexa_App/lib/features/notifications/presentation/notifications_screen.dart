import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/core/widgets/responsive_layout.dart';
import 'package:connexa/features/notifications/models/notification_models.dart';
import 'package:connexa/features/notifications/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedFilterIndex = 0; // 0 = All, 1 = Unread

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadNextPage();
    }
  }

  void _handleFilterChanged(int index) {
    if (_selectedFilterIndex == index) return;
    setState(() => _selectedFilterIndex = index);
    ref.read(notificationsProvider.notifier).loadNotifications(
          refresh: true,
          unreadOnly: index == 1,
        );
  }

  void _handleNotificationTap(AppNotification notif) {
    // Mark as read immediately
    if (!notif.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
    }

    // Deep-link navigation based on reference type and event
    final String? refType = notif.referenceType?.toLowerCase();
    final int? refId = notif.referenceId;

    if (refType == 'connection') {
      if (notif.eventType == 'ConnectionRequestReceived') {
        context.push('/network?tab=1'); // Pending requests tab
      } else {
        context.push('/network?tab=0'); // My Connections tab
      }
    } else if (refType == 'inquiry') {
      if (refId != null && refId > 0) {
        context.push('/inquiries/$refId');
      } else {
        context.push('/inquiries');
      }
    } else if (refType == 'product') {
      if (refId != null && refId > 0) {
        context.push('/products/$refId');
      } else {
        context.push('/products');
      }
    } else if (refType == 'rfq') {
      if (refId != null && refId > 0) {
        context.push('/rfqs/$refId');
      } else {
        context.push('/rfqs');
      }
    } else if (refType == 'order') {
      if (refId != null && refId > 0) {
        context.push('/orders/$refId');
      } else {
        context.push('/orders');
      }
    } else if (refType == 'job_work_requirement') {
      if (refId != null && refId > 0) {
        context.push('/job-works/$refId');
      } else {
        context.push('/job-works');
      }
    } else if (refType == 'job_work_order') {
      if (refId != null && refId > 0) {
        context.push('/job-work-orders/$refId');
      } else {
        context.push('/job-work-orders');
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'ConnectionRequestReceived':
        return Icons.person_add_rounded;
      case 'ConnectionRequestAccepted':
        return Icons.how_to_reg_rounded;
      case 'ConnectionRequestRejected':
        return Icons.person_remove_rounded;
      case 'ProductInquiryReceived':
        return Icons.mark_email_unread_rounded;
      case 'ProductInquiryResponded':
        return Icons.reply_all_rounded;
      case 'VerificationStatusChanged':
        return Icons.verified_user_rounded;
      case 'OrderCreated':
      case 'OrderConfirmed':
      case 'OrderProcessing':
      case 'OrderShipped':
      case 'OrderDelivered':
      case 'OrderCancelled':
      case 'OrderRejected':
        return Icons.shopping_bag_outlined;
      case 'JobWorkRequirementPublished':
      case 'JobWorkQuotationReceived':
      case 'JobWorkQuotationRevised':
      case 'JobWorkQuotationAccepted':
      case 'JobWorkQuotationRejected':
      case 'JobWorkQuotationRevisionRequested':
      case 'JobWorkOrderCreated':
      case 'JobWorkOrderConfirmed':
      case 'JobWorkOrderProcessing':
      case 'JobWorkOrderCompleted':
      case 'JobWorkOrderCancelled':
        return Icons.precision_manufacturing_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'ConnectionRequestReceived':
        return const Color(0xFF2563EB); // Royal Blue
      case 'ConnectionRequestAccepted':
        return const Color(0xFF059669); // Emerald
      case 'ConnectionRequestRejected':
        return const Color(0xFFDC2626); // Crimson
      case 'ProductInquiryReceived':
        return const Color(0xFFD97706); // Amber
      case 'ProductInquiryResponded':
        return const Color(0xFF0284C7); // Sky Blue
      case 'VerificationStatusChanged':
        return const Color(0xFF7C3AED); // Purple
      case 'OrderCreated':
      case 'OrderConfirmed':
        return const Color(0xFF2563EB); // Royal Blue
      case 'OrderProcessing':
        return const Color(0xFF7C3AED); // Purple
      case 'OrderShipped':
        return const Color(0xFF0284C7); // Sky Blue
      case 'OrderDelivered':
        return const Color(0xFF059669); // Emerald
      case 'OrderCancelled':
      case 'OrderRejected':
        return const Color(0xFFDC2626); // Crimson
      case 'JobWorkQuotationAccepted':
      case 'JobWorkOrderCompleted':
        return const Color(0xFF059669); // Emerald
      case 'JobWorkQuotationRejected':
      case 'JobWorkOrderCancelled':
        return const Color(0xFFDC2626); // Crimson
      case 'JobWorkOrderProcessing':
        return const Color(0xFFD97706); // Amber
      case 'JobWorkRequirementPublished':
      case 'JobWorkQuotationReceived':
      case 'JobWorkOrderCreated':
        return const Color(0xFF4338CA); // Indigo
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationsState state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: const Color(0xFF062747), // Deep Navy
          elevation: 0,
          toolbarHeight: 64,
          leading: IconButton(
            key: const Key('notificationsBackButton'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Notifications',
            key: Key('notificationsScreenTitle'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          actions: <Widget>[
            if (state.unreadCount > 0)
              TextButton.icon(
                key: const Key('markAllNotificationsReadButton'),
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllAsRead(),
                icon: const Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              // Filter Chips Strip
              _buildFilterStrip(state),

              // Notification List / States
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterStrip(NotificationsState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showCounter = constraints.maxWidth >= 340;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: <Widget>[
              _buildFilterChip(
                key: const Key('notificationsFilterAll'),
                label: 'All',
                isSelected: _selectedFilterIndex == 0,
                onTap: () => _handleFilterChanged(0),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                key: const Key('notificationsFilterUnread'),
                label: 'Unread',
                count: state.unreadCount,
                isSelected: _selectedFilterIndex == 1,
                onTap: () => _handleFilterChanged(1),
              ),
              if (showCounter && state.totalCount > 0) ...<Widget>[
                const Spacer(),
                Text(
                  '${state.totalCount} notification${state.totalCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (count != null && count > 0) ...<Widget>[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: AppLoadingIndicator(message: 'Loading notifications...'),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: AppErrorState(
          title: 'Notifications Unavailable',
          description: state.errorMessage!,
          retryLabel: 'Retry',
          onRetry: () => ref
              .read(notificationsProvider.notifier)
              .loadNotifications(refresh: true),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: AppEmptyState(
          key: const Key('notificationsEmptyState'),
          icon: Icons.notifications_off_outlined,
          title: _selectedFilterIndex == 1
              ? 'No Unread Notifications'
              : 'No Notifications Yet',
          description: _selectedFilterIndex == 1
              ? 'You have read all your notifications.'
              : "You're all caught up! Connection requests and product inquiries will appear here.",
          actionLabel: _selectedFilterIndex == 1 ? 'Show All' : null,
          onAction: _selectedFilterIndex == 1
              ? () => _handleFilterChanged(0)
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(notificationsProvider.notifier)
          .loadNotifications(refresh: true),
      child: ListView.separated(
        key: const Key('notificationsListView'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: state.items.length + (state.isPaginating ? 1 : 0),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final AppNotification notif = state.items[index];
          return _buildNotificationCard(notif);
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    final Color eventColor = _getEventColor(notif.eventType);
    final IconData eventIcon = _getEventIcon(notif.eventType);

    return Container(
      key: Key('notificationItem_${notif.id}'),
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFBFDBFE),
          width: notif.isRead ? 1.0 : 1.25,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: notif.isRead ? 0.015 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notif),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Event Icon Container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(eventIcon, color: eventColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Title & Unread Dot Row
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimeAgo(notif.createdAtUtc),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!notif.isRead) ...<Widget>[
                            const SizedBox(width: 6),
                            Container(
                              key: Key('unreadDot_${notif.id}'),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Message
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: notif.isRead
                              ? const Color(0xFF64748B)
                              : const Color(0xFF334155),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Actor company attribution tag if available
                      if (notif.actorCompanyName != null &&
                          notif.actorCompanyName!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notif.actorCompanyName!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
