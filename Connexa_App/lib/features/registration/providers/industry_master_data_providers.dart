import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/services/industry_master_data_service.dart';

/// Provider for the [IndustryMasterDataService].
final Provider<IndustryMasterDataService> industryMasterDataServiceProvider =
    Provider<IndustryMasterDataService>((Ref ref) {
      return IndustryMasterDataService(ref.watch(dioProvider));
    });

/// Fetches and caches the top-level list of [Industry] options.
final FutureProvider<List<Industry>> industriesProvider =
    FutureProvider<List<Industry>>((Ref ref) async {
      final IndustryMasterDataService service = ref.watch(
        industryMasterDataServiceProvider,
      );
      return service.getIndustries();
    });

/// Family provider fetching and caching [BusinessGroup] options for a specific integer [industryId].
final FutureProviderFamily<List<BusinessGroup>, int> businessGroupsProvider =
    FutureProvider.family<List<BusinessGroup>, int>((
      Ref ref,
      int industryId,
    ) async {
      if (industryId <= 0) {
        return const <BusinessGroup>[];
      }
      final IndustryMasterDataService service = ref.watch(
        industryMasterDataServiceProvider,
      );
      return service.getBusinessGroups(industryId);
    });

/// Family provider fetching and caching [SubGroup] options for a specific integer [businessGroupId].
final FutureProviderFamily<List<SubGroup>, int> subGroupsProvider =
    FutureProvider.family<List<SubGroup>, int>((
      Ref ref,
      int businessGroupId,
    ) async {
      if (businessGroupId <= 0) {
        return const <SubGroup>[];
      }
      final IndustryMasterDataService service = ref.watch(
        industryMasterDataServiceProvider,
      );
      return service.getSubGroups(businessGroupId);
    });

/// Family provider fetching and caching [Category] options for a specific integer [subGroupId].
final FutureProviderFamily<List<Category>, int> categoriesProvider =
    FutureProvider.family<List<Category>, int>((Ref ref, int subGroupId) async {
      if (subGroupId <= 0) {
        return const <Category>[];
      }
      final IndustryMasterDataService service = ref.watch(
        industryMasterDataServiceProvider,
      );
      return service.getCategories(subGroupId);
    });

/// State of the interactive 4-tier selection hierarchy.
@immutable
class IndustryHierarchyState {
  const IndustryHierarchyState({
    this.selectedIndustry,
    this.selectedBusinessGroup,
    this.selectedSubGroup,
    this.selectedCategory,
    this.validationError,
  });

  final Industry? selectedIndustry;
  final BusinessGroup? selectedBusinessGroup;
  final SubGroup? selectedSubGroup;
  final Category? selectedCategory;
  final String? validationError;

  bool get isComplete =>
      selectedIndustry != null &&
      selectedBusinessGroup != null &&
      selectedSubGroup != null &&
      selectedCategory != null;

  IndustrySelection? toSelection() {
    if (!isComplete) {
      return null;
    }
    return IndustrySelection(
      industryId: selectedIndustry!.id,
      industryName: selectedIndustry!.name,
      businessGroupId: selectedBusinessGroup!.id,
      businessGroupName: selectedBusinessGroup!.name,
      subGroupId: selectedSubGroup!.id,
      subGroupName: selectedSubGroup!.name,
      categoryId: selectedCategory!.id,
      categoryName: selectedCategory!.name,
    );
  }

  IndustryHierarchyState copyWith({
    Industry? selectedIndustry,
    bool clearIndustry = false,
    BusinessGroup? selectedBusinessGroup,
    bool clearBusinessGroup = false,
    SubGroup? selectedSubGroup,
    bool clearSubGroup = false,
    Category? selectedCategory,
    bool clearCategory = false,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return IndustryHierarchyState(
      selectedIndustry: clearIndustry
          ? null
          : (selectedIndustry ?? this.selectedIndustry),
      selectedBusinessGroup: clearBusinessGroup
          ? null
          : (selectedBusinessGroup ?? this.selectedBusinessGroup),
      selectedSubGroup: clearSubGroup
          ? null
          : (selectedSubGroup ?? this.selectedSubGroup),
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }
}

/// State notifier managing dependent cascading selections and clearing descendants.
class IndustryHierarchyNotifier extends StateNotifier<IndustryHierarchyState> {
  IndustryHierarchyNotifier([IndustryHierarchyState? initial])
    : super(initial ?? const IndustryHierarchyState());

  /// Sets the selected industry, resetting all child tiers.
  void selectIndustry(Industry? industry) {
    if (state.selectedIndustry == industry) {
      return;
    }
    state = state.copyWith(
      selectedIndustry: industry,
      clearIndustry: industry == null,
      clearBusinessGroup: true,
      clearSubGroup: true,
      clearCategory: true,
      clearValidationError: true,
    );
  }

  /// Sets the selected business group, resetting lower tiers.
  void selectBusinessGroup(BusinessGroup? businessGroup) {
    if (state.selectedBusinessGroup == businessGroup) {
      return;
    }
    state = state.copyWith(
      selectedBusinessGroup: businessGroup,
      clearBusinessGroup: businessGroup == null,
      clearSubGroup: true,
      clearCategory: true,
      clearValidationError: true,
    );
  }

  /// Sets the selected sub-group, resetting categories.
  void selectSubGroup(SubGroup? subGroup) {
    if (state.selectedSubGroup == subGroup) {
      return;
    }
    state = state.copyWith(
      selectedSubGroup: subGroup,
      clearSubGroup: subGroup == null,
      clearCategory: true,
      clearValidationError: true,
    );
  }

  /// Sets the selected category.
  void selectCategory(Category? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
      clearValidationError: true,
    );
  }

  void setValidationError(String? error) {
    state = state.copyWith(
      validationError: error,
      clearValidationError: error == null,
    );
  }

  /// Restores complete 4-tier selection from a saved IndustrySelection.
  void restoreFromSelection(IndustrySelection selection) {
    state = IndustryHierarchyState(
      selectedIndustry: Industry(
        id: selection.industryId,
        name: selection.industryName,
      ),
      selectedBusinessGroup: BusinessGroup(
        id: selection.businessGroupId,
        industryId: selection.industryId,
        name: selection.businessGroupName,
      ),
      selectedSubGroup: SubGroup(
        id: selection.subGroupId,
        businessGroupId: selection.businessGroupId,
        name: selection.subGroupName,
      ),
      selectedCategory: Category(
        id: selection.categoryId,
        subGroupId: selection.subGroupId,
        name: selection.categoryName,
      ),
    );
  }

  void reset() {
    state = const IndustryHierarchyState();
  }
}

/// Provider managing the active selection state.
final StateNotifierProvider<IndustryHierarchyNotifier, IndustryHierarchyState>
industryHierarchyProvider =
    StateNotifierProvider<IndustryHierarchyNotifier, IndustryHierarchyState>(
      (Ref ref) => IndustryHierarchyNotifier(),
    );
