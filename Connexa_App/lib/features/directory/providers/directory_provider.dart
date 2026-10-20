import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/directory/models/directory_models.dart';
import 'package:connexa/features/directory/services/directory_service.dart';

class DirectoryState {
  const DirectoryState({
    this.filter = const BusinessDirectoryFilter(),
    this.response,
    this.isLoading = false,
    this.errorMessage,
  });

  final BusinessDirectoryFilter filter;
  final BusinessDirectoryResponse? response;
  final bool isLoading;
  final String? errorMessage;

  List<BusinessDirectoryItem> get items =>
      response?.items ?? const <BusinessDirectoryItem>[];
  int get totalCount => response?.totalCount ?? 0;
  int get totalPages => response?.totalPages ?? 1;
  int get currentPage => response?.page ?? 1;
  bool get hasActiveFilters => filter.hasActiveFilters;

  DirectoryState copyWith({
    BusinessDirectoryFilter? filter,
    BusinessDirectoryResponse? response,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DirectoryState(
      filter: filter ?? this.filter,
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DirectoryNotifier extends StateNotifier<DirectoryState> {
  DirectoryNotifier(this._service) : super(const DirectoryState()) {
    loadDirectory();
  }

  final DirectoryService _service;
  Timer? _searchDebounceTimer;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _cancelToken?.cancel('Notifier disposed');
    super.dispose();
  }

  Future<void> loadDirectory() async {
    // Cancel any previous in-flight request to prevent race conditions
    _cancelToken?.cancel('New query initiated');
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final BusinessDirectoryResponse res = await _service.searchBusinesses(
        state.filter,
        cancelToken: _cancelToken,
      );
      state = state.copyWith(isLoading: false, response: res);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Ignored superseded cancelled request
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Sets search query. If [immediate] is false, debounces for 400ms.
  void setSearch(String? search, {bool immediate = false}) {
    _searchDebounceTimer?.cancel();

    state = state.copyWith(
      filter: state.filter.copyWith(
        search: search,
        page: 1,
        clearSearch: search == null || search.trim().isEmpty,
      ),
    );

    if (immediate) {
      loadDirectory();
    } else {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
        loadDirectory();
      });
    }
  }

  void setBusinessType(String? businessType) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        businessType: businessType,
        page: 1,
        clearBusinessType:
            businessType == null ||
            businessType.isEmpty ||
            businessType == 'All',
      ),
    );
    loadDirectory();
  }

  void setIndustry(int? industryId) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        industryId: industryId,
        page: 1,
        clearIndustry: industryId == null,
        clearBusinessGroup: true,
        clearSubGroup: true,
        clearCategory: true,
      ),
    );
    loadDirectory();
  }

  void setBusinessGroup(int? groupId) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        businessGroupId: groupId,
        page: 1,
        clearBusinessGroup: groupId == null,
        clearSubGroup: true,
        clearCategory: true,
      ),
    );
    loadDirectory();
  }

  void setSubGroup(int? subGroupId) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        subGroupId: subGroupId,
        page: 1,
        clearSubGroup: subGroupId == null,
        clearCategory: true,
      ),
    );
    loadDirectory();
  }

  void setCategory(int? categoryId) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        categoryId: categoryId,
        page: 1,
        clearCategory: categoryId == null,
      ),
    );
    loadDirectory();
  }

  void setCapability(String? capability) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        capability: capability,
        page: 1,
        clearCapability: capability == null || capability.isEmpty,
      ),
    );
    loadDirectory();
  }

  void setLocation(String? location) {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: state.filter.copyWith(
        location: location,
        page: 1,
        clearLocation: location == null || location.isEmpty,
      ),
    );
    loadDirectory();
  }

  void setPage(int page) {
    if (page == state.currentPage || state.isLoading) return;
    state = state.copyWith(filter: state.filter.copyWith(page: page));
    loadDirectory();
  }

  void resetFilters() {
    _searchDebounceTimer?.cancel();
    state = state.copyWith(
      filter: const BusinessDirectoryFilter(page: 1, pageSize: 10),
    );
    loadDirectory();
  }

  void updateItemConnectionStatus(int memberId, String newStatus) {
    if (state.response == null) return;
    final List<BusinessDirectoryItem> updatedItems = state.items.map((
      BusinessDirectoryItem item,
    ) {
      if (item.memberId == memberId) {
        return item.copyWith(connectionStatus: newStatus);
      }
      return item;
    }).toList();

    state = state.copyWith(
      response: BusinessDirectoryResponse(
        items: updatedItems,
        totalCount: state.totalCount,
        page: state.currentPage,
        pageSize: state.response!.pageSize,
        totalPages: state.totalPages,
      ),
    );
  }
}

final StateNotifierProvider<DirectoryNotifier, DirectoryState>
directoryNotifierProvider =
    StateNotifierProvider<DirectoryNotifier, DirectoryState>((Ref ref) {
      final DirectoryService service = ref.watch(directoryServiceProvider);
      return DirectoryNotifier(service);
    });
