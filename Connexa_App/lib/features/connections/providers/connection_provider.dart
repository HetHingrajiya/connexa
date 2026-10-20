import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/connections/models/connection_models.dart';
import 'package:connexa/features/connections/services/connection_service.dart';

class ConnectionsState {
  const ConnectionsState({
    this.activeTab = 0,
    this.connections = const <ConnectedMemberItem>[],
    this.receivedRequests = const <ConnectionRequestItem>[],
    this.sentRequests = const <ConnectionRequestItem>[],
    this.summary = const ConnectionsSummary(),
    this.isLoadingConnections = false,
    this.isLoadingReceived = false,
    this.isLoadingSent = false,
    this.isProcessingAction = false,
    this.processingId,
    this.errorMessage,
    this.searchQuery = '',
    this.connectionsPage = 1,
    this.connectionsTotalPages = 1,
    this.connectionsTotalCount = 0,
    this.receivedPage = 1,
    this.receivedTotalPages = 1,
    this.receivedTotalCount = 0,
    this.sentPage = 1,
    this.sentTotalPages = 1,
    this.sentTotalCount = 0,
  });

  final int activeTab; // 0: My Network, 1: Received, 2: Sent
  final List<ConnectedMemberItem> connections;
  final List<ConnectionRequestItem> receivedRequests;
  final List<ConnectionRequestItem> sentRequests;
  final ConnectionsSummary summary;
  final bool isLoadingConnections;
  final bool isLoadingReceived;
  final bool isLoadingSent;
  final bool isProcessingAction;
  final int? processingId;
  final String? errorMessage;
  final String searchQuery;
  final int connectionsPage;
  final int connectionsTotalPages;
  final int connectionsTotalCount;
  final int receivedPage;
  final int receivedTotalPages;
  final int receivedTotalCount;
  final int sentPage;
  final int sentTotalPages;
  final int sentTotalCount;

  bool get isLoadingAny =>
      isLoadingConnections || isLoadingReceived || isLoadingSent;

  ConnectionsState copyWith({
    int? activeTab,
    List<ConnectedMemberItem>? connections,
    List<ConnectionRequestItem>? receivedRequests,
    List<ConnectionRequestItem>? sentRequests,
    ConnectionsSummary? summary,
    bool? isLoadingConnections,
    bool? isLoadingReceived,
    bool? isLoadingSent,
    bool? isProcessingAction,
    int? processingId,
    bool clearProcessingId = false,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    int? connectionsPage,
    int? connectionsTotalPages,
    int? connectionsTotalCount,
    int? receivedPage,
    int? receivedTotalPages,
    int? receivedTotalCount,
    int? sentPage,
    int? sentTotalPages,
    int? sentTotalCount,
  }) {
    return ConnectionsState(
      activeTab: activeTab ?? this.activeTab,
      connections: connections ?? this.connections,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      summary: summary ?? this.summary,
      isLoadingConnections: isLoadingConnections ?? this.isLoadingConnections,
      isLoadingReceived: isLoadingReceived ?? this.isLoadingReceived,
      isLoadingSent: isLoadingSent ?? this.isLoadingSent,
      isProcessingAction: isProcessingAction ?? this.isProcessingAction,
      processingId: clearProcessingId
          ? null
          : (processingId ?? this.processingId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      connectionsPage: connectionsPage ?? this.connectionsPage,
      connectionsTotalPages:
          connectionsTotalPages ?? this.connectionsTotalPages,
      connectionsTotalCount:
          connectionsTotalCount ?? this.connectionsTotalCount,
      receivedPage: receivedPage ?? this.receivedPage,
      receivedTotalPages: receivedTotalPages ?? this.receivedTotalPages,
      receivedTotalCount: receivedTotalCount ?? this.receivedTotalCount,
      sentPage: sentPage ?? this.sentPage,
      sentTotalPages: sentTotalPages ?? this.sentTotalPages,
      sentTotalCount: sentTotalCount ?? this.sentTotalCount,
    );
  }
}

class ConnectionsNotifier extends StateNotifier<ConnectionsState> {
  ConnectionsNotifier(this._service) : super(const ConnectionsState()) {
    loadAll();
  }

  final ConnectionService _service;
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadAll() async {
    await Future.wait<void>(<Future<void>>[
      loadSummary(),
      loadConnections(),
      loadReceivedRequests(),
      loadSentRequests(),
    ]);
  }

  void setActiveTab(int tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
  }

  void setSearch(String search, {bool immediate = false}) {
    _searchDebounceTimer?.cancel();
    if (immediate) {
      state = state.copyWith(searchQuery: search, connectionsPage: 1);
      loadConnections();
    } else {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
        state = state.copyWith(searchQuery: search, connectionsPage: 1);
        loadConnections();
      });
    }
  }

  Future<void> loadSummary() async {
    try {
      final ConnectionsSummary summary = await _service.getSummary();
      state = state.copyWith(summary: summary);
    } catch (_) {
      // Ignored non-critical failure
    }
  }

  Future<void> loadConnections({int? page}) async {
    final int targetPage = page ?? state.connectionsPage;
    state = state.copyWith(isLoadingConnections: true, clearError: true);

    try {
      final PaginatedList<ConnectedMemberItem> result = await _service
          .getMyConnections(
            search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
            page: targetPage,
          );

      state = state.copyWith(
        connections: result.items,
        connectionsTotalCount: result.totalCount,
        connectionsPage: result.page,
        connectionsTotalPages: result.totalPages,
        isLoadingConnections: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingConnections: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadReceivedRequests({int? page}) async {
    final int targetPage = page ?? state.receivedPage;
    state = state.copyWith(isLoadingReceived: true, clearError: true);

    try {
      final PaginatedList<ConnectionRequestItem> result = await _service
          .getReceivedRequests(page: targetPage);

      state = state.copyWith(
        receivedRequests: result.items,
        receivedTotalCount: result.totalCount,
        receivedPage: result.page,
        receivedTotalPages: result.totalPages,
        isLoadingReceived: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingReceived: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadSentRequests({int? page}) async {
    final int targetPage = page ?? state.sentPage;
    state = state.copyWith(isLoadingSent: true, clearError: true);

    try {
      final PaginatedList<ConnectionRequestItem> result = await _service
          .getSentRequests(page: targetPage);

      state = state.copyWith(
        sentRequests: result.items,
        sentTotalCount: result.totalCount,
        sentPage: result.page,
        sentTotalPages: result.totalPages,
        isLoadingSent: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSent: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> sendConnectionRequest({
    required int recipientMemberId,
    String? note,
  }) async {
    state = state.copyWith(isProcessingAction: true, clearError: true);

    try {
      await _service.sendRequest(
        recipientMemberId: recipientMemberId,
        note: note,
      );
      await Future.wait<void>(<Future<void>>[
        loadSentRequests(page: 1),
        loadSummary(),
      ]);
      state = state.copyWith(isProcessingAction: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingAction: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> acceptRequest(int requestId) async {
    state = state.copyWith(
      isProcessingAction: true,
      processingId: requestId,
      clearError: true,
    );

    try {
      await _service.acceptRequest(requestId);
      await Future.wait<void>(<Future<void>>[
        loadReceivedRequests(page: 1),
        loadConnections(page: 1),
        loadSummary(),
      ]);
      state = state.copyWith(
        isProcessingAction: false,
        clearProcessingId: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingAction: false,
        clearProcessingId: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> rejectRequest(int requestId) async {
    state = state.copyWith(
      isProcessingAction: true,
      processingId: requestId,
      clearError: true,
    );

    try {
      await _service.rejectRequest(requestId);
      await Future.wait<void>(<Future<void>>[
        loadReceivedRequests(page: 1),
        loadSummary(),
      ]);
      state = state.copyWith(
        isProcessingAction: false,
        clearProcessingId: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingAction: false,
        clearProcessingId: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> cancelRequest(int requestId) async {
    state = state.copyWith(
      isProcessingAction: true,
      processingId: requestId,
      clearError: true,
    );

    try {
      await _service.cancelRequest(requestId);
      await Future.wait<void>(<Future<void>>[
        loadSentRequests(page: 1),
        loadSummary(),
      ]);
      state = state.copyWith(
        isProcessingAction: false,
        clearProcessingId: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingAction: false,
        clearProcessingId: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> removeConnection(int memberId) async {
    state = state.copyWith(isProcessingAction: true, clearError: true);

    try {
      await _service.removeConnection(memberId);
      await Future.wait<void>(<Future<void>>[
        loadConnections(page: 1),
        loadSummary(),
      ]);
      state = state.copyWith(isProcessingAction: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingAction: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final StateNotifierProvider<ConnectionsNotifier, ConnectionsState>
connectionsNotifierProvider =
    StateNotifierProvider<ConnectionsNotifier, ConnectionsState>((Ref ref) {
      final ConnectionService service = ref.watch(connectionServiceProvider);
      return ConnectionsNotifier(service);
    });
