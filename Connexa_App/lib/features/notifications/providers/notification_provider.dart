import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/notifications/models/notification_models.dart';
import 'package:connexa/features/notifications/services/notification_service.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const <AppNotification>[],
    this.totalCount = 0,
    this.unreadCount = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.isLoading = false,
    this.isPaginating = false,
    this.errorMessage,
    this.unreadOnly,
  });

  final List<AppNotification> items;
  final int totalCount;
  final int unreadCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool isLoading;
  final bool isPaginating;
  final String? errorMessage;
  final bool? unreadOnly;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? totalCount,
    int? unreadCount,
    int? page,
    int? pageSize,
    int? totalPages,
    bool? isLoading,
    bool? isPaginating,
    String? errorMessage,
    bool? unreadOnly,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._service) : super(const NotificationsState()) {
    loadNotifications();
  }

  final NotificationService _service;

  Future<void> loadNotifications({
    bool refresh = false,
    bool? unreadOnly,
  }) async {
    final bool newFilter = unreadOnly ?? state.unreadOnly ?? false;
    final bool filterChanged = unreadOnly != null && unreadOnly != state.unreadOnly;

    if (refresh || filterChanged || state.items.isEmpty) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        unreadOnly: unreadOnly,
        page: 1,
      );
    }

    try {
      final NotificationListResponse res = await _service.getNotifications(
        page: 1,
        pageSize: state.pageSize,
        unreadOnly: newFilter ? true : null,
      );

      state = state.copyWith(
        items: res.items,
        totalCount: res.totalCount,
        unreadCount: res.unreadCount,
        page: res.page,
        totalPages: res.totalPages,
        isLoading: false,
        clearError: true,
        unreadOnly: newFilter ? true : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isPaginating || state.page >= state.totalPages) {
      return;
    }

    state = state.copyWith(isPaginating: true);

    try {
      final int nextPage = state.page + 1;
      final NotificationListResponse res = await _service.getNotifications(
        page: nextPage,
        pageSize: state.pageSize,
        unreadOnly: state.unreadOnly,
      );

      state = state.copyWith(
        items: <AppNotification>[...state.items, ...res.items],
        totalCount: res.totalCount,
        unreadCount: res.unreadCount,
        page: res.page,
        totalPages: res.totalPages,
        isPaginating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isPaginating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> markAsRead(int notificationId) async {
    // Optimistic UI update
    final int index = state.items.indexWhere((AppNotification n) => n.id == notificationId);
    if (index != -1 && !state.items[index].isRead) {
      final List<AppNotification> updated = List<AppNotification>.from(state.items);
      updated[index] = updated[index].copyWith(
        isRead: true,
        readAtUtc: DateTime.now(),
      );

      final int newUnread = (state.unreadCount - 1).clamp(0, 99999);
      state = state.copyWith(
        items: updated,
        unreadCount: newUnread,
      );

      try {
        await _service.markAsRead(notificationIds: <int>[notificationId]);
      } catch (_) {
        // Silently preserve optimistic state unless hard failure
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;

    final List<AppNotification> updated = state.items.map((AppNotification n) {
      return n.isRead ? n : n.copyWith(isRead: true, readAtUtc: DateTime.now());
    }).toList();

    state = state.copyWith(
      items: updated,
      unreadCount: 0,
    );

    try {
      await _service.markAsRead(markAll: true);
    } catch (_) {
      // Re-fetch on error to ensure sync
      await loadNotifications(refresh: true);
    }
  }
}

final StateNotifierProvider<NotificationsNotifier, NotificationsState>
    notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((Ref ref) {
      final NotificationService service = ref.watch(notificationServiceProvider);
      return NotificationsNotifier(service);
    });

final Provider<int> unreadNotificationsCountProvider = Provider<int>((Ref ref) {
  return ref.watch(notificationsProvider.select((NotificationsState s) => s.unreadCount));
});
