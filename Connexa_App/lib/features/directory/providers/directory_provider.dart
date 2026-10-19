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

  Future<void> loadDirectory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final BusinessDirectoryResponse res = await _service.searchBusinesses(
        state.filter,
      );
      state = state.copyWith(isLoading: false, response: res);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearch(String? search) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        search: search,
        page: 1,
        clearSearch: search == null || search.trim().isEmpty,
      ),
    );
    loadDirectory();
  }

  void setIndustry(int? industryId) {
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
    state = state.copyWith(
      filter: state.filter.copyWith(
        capability: capability,
        page: 1,
        clearCapability: capability == null || capability.isEmpty,
      ),
    );
    loadDirectory();
  }

  void setPage(int page) {
    if (page == state.currentPage) return;
    state = state.copyWith(filter: state.filter.copyWith(page: page));
    loadDirectory();
  }

  void resetFilters() {
    state = state.copyWith(
      filter: const BusinessDirectoryFilter(page: 1, pageSize: 10),
    );
    loadDirectory();
  }
}

final StateNotifierProvider<DirectoryNotifier, DirectoryState>
directoryNotifierProvider =
    StateNotifierProvider<DirectoryNotifier, DirectoryState>((Ref ref) {
      final DirectoryService service = ref.watch(directoryServiceProvider);
      return DirectoryNotifier(service);
    });
