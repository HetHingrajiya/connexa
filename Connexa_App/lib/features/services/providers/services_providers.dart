import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/services/models/service_models.dart';
import 'package:connexa/features/services/services/services_marketplace_service.dart';

// ==========================================
// 1. SERVICES MARKETPLACE FEED
// ==========================================

@immutable
class ServicesMarketplaceState {
  const ServicesMarketplaceState({
    this.services = const <ServiceSummary>[],
    this.isLoading = false,
    this.isPaginating = false,
    this.searchQuery,
    this.selectedCategory = 'All',
    this.selectedServiceType = 'All',
    this.selectedLocation,
    this.selectedIndustryId,
    this.page = 1,
    this.totalCount = 0,
    this.errorMessage,
  });

  final List<ServiceSummary> services;
  final bool isLoading;
  final bool isPaginating;
  final String? searchQuery;
  final String selectedCategory;
  final String selectedServiceType;
  final String? selectedLocation;
  final int? selectedIndustryId;
  final int page;
  final int totalCount;
  final String? errorMessage;

  ServicesMarketplaceState copyWith({
    List<ServiceSummary>? services,
    bool? isLoading,
    bool? isPaginating,
    String? searchQuery,
    String? selectedCategory,
    String? selectedServiceType,
    String? selectedLocation,
    int? selectedIndustryId,
    int? page,
    int? totalCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ServicesMarketplaceState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedServiceType: selectedServiceType ?? this.selectedServiceType,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedIndustryId: selectedIndustryId ?? this.selectedIndustryId,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ServicesMarketplaceNotifier extends StateNotifier<ServicesMarketplaceState> {
  ServicesMarketplaceNotifier(this._service)
      : super(const ServicesMarketplaceState()) {
    loadServices();
  }

  final ServicesMarketplaceService _service;

  Future<void> loadServices({bool refresh = false}) async {
    final int targetPage = refresh ? 1 : state.page;
    if (refresh) {
      state = state.copyWith(isLoading: true, page: 1, clearError: true);
    } else if (state.services.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final (List<ServiceSummary> list, int total) = await _service.searchServices(
        query: state.searchQuery,
        category: state.selectedCategory,
        industryId: state.selectedIndustryId,
        location: state.selectedLocation,
        serviceType: state.selectedServiceType,
        page: targetPage,
        pageSize: 20,
      );

      state = state.copyWith(
        services: refresh ? list : <ServiceSummary>[...state.services, ...list],
        totalCount: total,
        isLoading: false,
        isPaginating: false,
        page: targetPage,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        errorMessage: 'Failed to load services marketplace.',
      );
    }
  }

  void setSearchQuery(String? query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query, page: 1);
    loadServices(refresh: true);
  }

  void setCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category, page: 1);
    loadServices(refresh: true);
  }

  void setServiceType(String type) {
    if (state.selectedServiceType == type) return;
    state = state.copyWith(selectedServiceType: type, page: 1);
    loadServices(refresh: true);
  }

  void setLocation(String? location) {
    if (state.selectedLocation == location) return;
    state = state.copyWith(selectedLocation: location, page: 1);
    loadServices(refresh: true);
  }
}

final AutoDisposeStateNotifierProvider<ServicesMarketplaceNotifier,
        ServicesMarketplaceState> servicesMarketplaceProvider =
    StateNotifierProvider.autoDispose<ServicesMarketplaceNotifier,
        ServicesMarketplaceState>((Ref ref) {
  final ServicesMarketplaceService service =
      ref.watch(servicesMarketplaceServiceProvider);
  return ServicesMarketplaceNotifier(service);
});

// ==========================================
// 2. SERVICE CATEGORIES PROVIDER
// ==========================================

final AutoDisposeFutureProvider<List<String>> serviceCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((Ref ref) async {
  final ServicesMarketplaceService service =
      ref.watch(servicesMarketplaceServiceProvider);
  return service.getCategories();
});

// ==========================================
// 3. MY SERVICES
// ==========================================

@immutable
class MyServicesState {
  const MyServicesState({
    this.services = const <ServiceSummary>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ServiceSummary> services;
  final bool isLoading;
  final String? errorMessage;

  MyServicesState copyWith({
    List<ServiceSummary>? services,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyServicesState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MyServicesNotifier extends StateNotifier<MyServicesState> {
  MyServicesNotifier(this._service) : super(const MyServicesState()) {
    loadMyServices();
  }

  final ServicesMarketplaceService _service;

  Future<void> loadMyServices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<ServiceSummary> list = await _service.getMyServices();
      state = state.copyWith(services: list, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load your services.',
      );
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      final bool success = await _service.deleteService(id);
      if (success) {
        state = state.copyWith(
          services: state.services.where((ServiceSummary s) => s.id != id).toList(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final AutoDisposeStateNotifierProvider<MyServicesNotifier, MyServicesState>
    myServicesProvider =
    StateNotifierProvider.autoDispose<MyServicesNotifier, MyServicesState>(
        (Ref ref) {
  final ServicesMarketplaceService service =
      ref.watch(servicesMarketplaceServiceProvider);
  return MyServicesNotifier(service);
});

// ==========================================
// 4. SERVICE INQUIRIES
// ==========================================

@immutable
class ServiceInquiriesState {
  const ServiceInquiriesState({
    this.sentInquiries = const <ServiceInquiry>[],
    this.receivedInquiries = const <ServiceInquiry>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ServiceInquiry> sentInquiries;
  final List<ServiceInquiry> receivedInquiries;
  final bool isLoading;
  final String? errorMessage;

  ServiceInquiriesState copyWith({
    List<ServiceInquiry>? sentInquiries,
    List<ServiceInquiry>? receivedInquiries,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ServiceInquiriesState(
      sentInquiries: sentInquiries ?? this.sentInquiries,
      receivedInquiries: receivedInquiries ?? this.receivedInquiries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ServiceInquiriesNotifier extends StateNotifier<ServiceInquiriesState> {
  ServiceInquiriesNotifier(this._service)
      : super(const ServiceInquiriesState()) {
    loadInquiries();
  }

  final ServicesMarketplaceService _service;

  Future<void> loadInquiries() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<ServiceInquiry> sent = await _service.getMySentInquiries();
      final List<ServiceInquiry> received =
          await _service.getMyReceivedInquiries();
      state = state.copyWith(
        sentInquiries: sent,
        receivedInquiries: received,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load service inquiries.',
      );
    }
  }

  Future<bool> respondInquiry(
    int id,
    RespondServiceInquiryRequest request,
  ) async {
    try {
      final ServiceInquiry updated =
          await _service.respondInquiry(id, request);
      final List<ServiceInquiry> updatedList = state.receivedInquiries.map((ServiceInquiry i) {
        return i.id == id ? updated : i;
      }).toList();
      state = state.copyWith(receivedInquiries: updatedList);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(
    int id,
    ServiceInquiryStatus status,
    String? remarks,
  ) async {
    try {
      final ServiceInquiry updated =
          await _service.updateInquiryStatus(id, status, remarks);
      final List<ServiceInquiry> updatedSent = state.sentInquiries.map((ServiceInquiry i) {
        return i.id == id ? updated : i;
      }).toList();
      final List<ServiceInquiry> updatedReceived = state.receivedInquiries.map((ServiceInquiry i) {
        return i.id == id ? updated : i;
      }).toList();
      state = state.copyWith(
        sentInquiries: updatedSent,
        receivedInquiries: updatedReceived,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final AutoDisposeStateNotifierProvider<ServiceInquiriesNotifier,
        ServiceInquiriesState> serviceInquiriesProvider =
    StateNotifierProvider.autoDispose<ServiceInquiriesNotifier,
        ServiceInquiriesState>((Ref ref) {
  final ServicesMarketplaceService service =
      ref.watch(servicesMarketplaceServiceProvider);
  return ServiceInquiriesNotifier(service);
});

