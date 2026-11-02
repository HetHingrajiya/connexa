import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/services/job_work_service.dart';

// ==========================================
// 1. MARKETPLACE FEED PROVIDER
// ==========================================

@immutable
class JobWorkMarketplaceState {
  const JobWorkMarketplaceState({
    this.requirements = const <JobWorkRequirement>[],
    this.isLoading = false,
    this.isPaginating = false,
    this.errorMessage,
    this.searchQuery,
    this.selectedProcess,
    this.selectedLocation,
    this.selectedMaterial,
    this.page = 1,
    this.totalCount = 0,
    this.totalPages = 1,
  });

  final List<JobWorkRequirement> requirements;
  final bool isLoading;
  final bool isPaginating;
  final String? errorMessage;
  final String? searchQuery;
  final String? selectedProcess;
  final String? selectedLocation;
  final MaterialResponsibility? selectedMaterial;
  final int page;
  final int totalCount;
  final int totalPages;

  JobWorkMarketplaceState copyWith({
    List<JobWorkRequirement>? requirements,
    bool? isLoading,
    bool? isPaginating,
    String? errorMessage,
    String? searchQuery,
    String? selectedProcess,
    String? selectedLocation,
    MaterialResponsibility? selectedMaterial,
    int? page,
    int? totalCount,
    int? totalPages,
    bool clearError = false,
  }) {
    return JobWorkMarketplaceState(
      requirements: requirements ?? this.requirements,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProcess: selectedProcess ?? this.selectedProcess,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedMaterial: selectedMaterial ?? this.selectedMaterial,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class JobWorkMarketplaceNotifier
    extends StateNotifier<JobWorkMarketplaceState> {
  JobWorkMarketplaceNotifier(this._service)
      : super(const JobWorkMarketplaceState()) {
    loadMarketplace();
  }

  final JobWorkService _service;

  Future<void> loadMarketplace({bool isRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: isRefresh ? 1 : state.page,
    );

    try {
      final JobWorkRequirementListResponse response =
          await _service.getMarketplaceRequirements(
        search: state.searchQuery,
        process: state.selectedProcess,
        location: state.selectedLocation,
        materialResponsibility: state.selectedMaterial,
        page: isRefresh ? 1 : state.page,
        pageSize: 10,
      );

      state = state.copyWith(
        requirements: response.items,
        totalCount: response.totalCount,
        totalPages: response.totalPages,
        page: response.page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load requirements. Please try again.',
      );
    }
  }

  void setSearch(String? query) {
    state = state.copyWith(searchQuery: query, page: 1);
    loadMarketplace(isRefresh: true);
  }

  void setProcess(String? process) {
    if (state.selectedProcess == process) {
      state = state.copyWith(selectedProcess: null, page: 1);
    } else {
      state = state.copyWith(selectedProcess: process, page: 1);
    }
    loadMarketplace(isRefresh: true);
  }

  void setFilters({
    String? location,
    MaterialResponsibility? material,
  }) {
    state = state.copyWith(
      selectedLocation: location,
      selectedMaterial: material,
      page: 1,
    );
    loadMarketplace(isRefresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: null,
      selectedProcess: null,
      selectedLocation: null,
      selectedMaterial: null,
      page: 1,
    );
    loadMarketplace(isRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isPaginating || state.page >= state.totalPages) {
      return;
    }

    state = state.copyWith(isPaginating: true);
    final int nextPage = state.page + 1;

    try {
      final JobWorkRequirementListResponse response =
          await _service.getMarketplaceRequirements(
        search: state.searchQuery,
        process: state.selectedProcess,
        location: state.selectedLocation,
        materialResponsibility: state.selectedMaterial,
        page: nextPage,
        pageSize: 10,
      );

      state = state.copyWith(
        requirements: <JobWorkRequirement>[
          ...state.requirements,
          ...response.items,
        ],
        page: nextPage,
        totalCount: response.totalCount,
        totalPages: response.totalPages,
        isPaginating: false,
      );
    } catch (_) {
      state = state.copyWith(isPaginating: false);
    }
  }
}

final StateNotifierProvider<JobWorkMarketplaceNotifier, JobWorkMarketplaceState>
    jobWorkMarketplaceProvider = StateNotifierProvider<
        JobWorkMarketplaceNotifier, JobWorkMarketplaceState>((Ref ref) {
  final JobWorkService service = ref.watch(jobWorkServiceProvider);
  return JobWorkMarketplaceNotifier(service);
});

// ==========================================
// 2. MY REQUIREMENTS PROVIDER
// ==========================================

@immutable
class MyJobWorkRequirementsState {
  const MyJobWorkRequirementsState({
    this.requirements = const <JobWorkRequirement>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<JobWorkRequirement> requirements;
  final bool isLoading;
  final String? errorMessage;

  MyJobWorkRequirementsState copyWith({
    List<JobWorkRequirement>? requirements,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyJobWorkRequirementsState(
      requirements: requirements ?? this.requirements,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MyJobWorkRequirementsNotifier
    extends StateNotifier<MyJobWorkRequirementsState> {
  MyJobWorkRequirementsNotifier(this._service)
      : super(const MyJobWorkRequirementsState()) {
    loadMyRequirements();
  }

  final JobWorkService _service;

  Future<void> loadMyRequirements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final JobWorkRequirementListResponse response =
          await _service.getMyRequirements(page: 1, pageSize: 50);
      state = state.copyWith(
        requirements: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load your requirements.',
      );
    }
  }
}

final StateNotifierProvider<MyJobWorkRequirementsNotifier,
        MyJobWorkRequirementsState> myJobWorkRequirementsProvider =
    StateNotifierProvider<MyJobWorkRequirementsNotifier,
        MyJobWorkRequirementsState>((Ref ref) {
  final JobWorkService service = ref.watch(jobWorkServiceProvider);
  return MyJobWorkRequirementsNotifier(service);
});

// ==========================================
// 3. REQUIREMENT DETAILS & QUOTATIONS PROVIDER
// ==========================================

@immutable
class JobWorkDetailsState {
  const JobWorkDetailsState({
    this.requirement,
    this.quotations = const <JobWorkQuotation>[],
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
  });

  final JobWorkRequirement? requirement;
  final List<JobWorkQuotation> quotations;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;

  JobWorkDetailsState copyWith({
    JobWorkRequirement? requirement,
    List<JobWorkQuotation>? quotations,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JobWorkDetailsState(
      requirement: requirement ?? this.requirement,
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class JobWorkDetailsNotifier extends StateNotifier<JobWorkDetailsState> {
  JobWorkDetailsNotifier(this._service, this._requirementId)
      : super(const JobWorkDetailsState()) {
    loadDetails();
  }

  final JobWorkService _service;
  final int _requirementId;

  Future<void> loadDetails() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final JobWorkRequirement req =
          await _service.getRequirementById(_requirementId);
      final List<JobWorkQuotation> quotes =
          await _service.getQuotationsForRequirement(_requirementId);

      state = state.copyWith(
        requirement: req,
        quotations: quotes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load requirement details.',
      );
    }
  }

  Future<bool> submitQuotation({
    required double offeredUnitPrice,
    required double quantity,
    double taxRatePercent = 18.0,
    double otherCharges = 0.0,
    int leadTimeDays = 7,
    String? machineProposed,
    String? technicalRemarks,
    String? termsAndConditions,
    List<int>? attachmentIds,
  }) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await _service.submitQuotation(
        requirementId: _requirementId,
        offeredUnitPrice: offeredUnitPrice,
        quantity: quantity,
        taxRatePercent: taxRatePercent,
        otherCharges: otherCharges,
        leadTimeDays: leadTimeDays,
        machineProposed: machineProposed,
        technicalRemarks: technicalRemarks,
        termsAndConditions: termsAndConditions,
        attachmentIds: attachmentIds,
      );

      await loadDetails();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> decideQuotation({
    required int quotationId,
    required String decision, // "Accept", "Reject", "RequestRevision"
    String? notes,
  }) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await _service.decideQuotation(
        quotationId: quotationId,
        decision: decision,
        notes: notes,
      );

      await loadDetails();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> withdrawQuotation(int quotationId) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await _service.withdrawQuotation(quotationId);
      await loadDetails();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final StateNotifierProviderFamily<JobWorkDetailsNotifier, JobWorkDetailsState,
        int> jobWorkDetailsProvider =
    StateNotifierProvider.family<JobWorkDetailsNotifier, JobWorkDetailsState, int>(
        (Ref ref, int id) {
  final JobWorkService service = ref.watch(jobWorkServiceProvider);
  return JobWorkDetailsNotifier(service, id);
});

// ==========================================
// 4. JOB WORK ORDERS PROVIDER
// ==========================================

@immutable
class JobWorkOrdersState {
  const JobWorkOrdersState({
    this.orders = const <JobWorkOrder>[],
    this.isLoading = false,
    this.errorMessage,
    this.statusFilter,
  });

  final List<JobWorkOrder> orders;
  final bool isLoading;
  final String? errorMessage;
  final JobWorkOrderStatus? statusFilter;

  JobWorkOrdersState copyWith({
    List<JobWorkOrder>? orders,
    bool? isLoading,
    String? errorMessage,
    JobWorkOrderStatus? statusFilter,
    bool clearStatusFilter = false,
    bool clearError = false,
  }) {
    return JobWorkOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class JobWorkOrdersNotifier extends StateNotifier<JobWorkOrdersState> {
  JobWorkOrdersNotifier(this._service, this._role)
      : super(const JobWorkOrdersState()) {
    loadOrders();
  }

  final JobWorkService _service;
  final String _role; // 'buyer' or 'contractor'

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final JobWorkOrderListResponse response = await _service.getOrders(
        role: _role,
        status: state.statusFilter,
        page: 1,
        pageSize: 50,
      );
      state = state.copyWith(
        orders: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load job work orders.',
      );
    }
  }

  void filterByStatus(JobWorkOrderStatus? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
    loadOrders();
  }

  Future<bool> updateStatus(int orderId, JobWorkOrderStatus newStatus, {String? remarks}) async {
    try {
      await _service.updateOrderStatus(orderId: orderId, newStatus: newStatus, remarks: remarks);
      await loadOrders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      await _service.cancelOrder(orderId: orderId, reason: reason);
      await loadOrders();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final StateNotifierProviderFamily<JobWorkOrdersNotifier, JobWorkOrdersState,
        String> jobWorkOrdersProvider =
    StateNotifierProvider.family<JobWorkOrdersNotifier, JobWorkOrdersState, String>(
        (Ref ref, String role) {
  final JobWorkService service = ref.watch(jobWorkServiceProvider);
  return JobWorkOrdersNotifier(service, role);
});

