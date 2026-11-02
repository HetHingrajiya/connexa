import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/services/rfq_service.dart';

/// Provider for single RFQ details by ID.
final AutoDisposeFutureProviderFamily<Rfq, int> rfqDetailsProvider =
    FutureProvider.autoDispose.family<Rfq, int>((Ref ref, int id) async {
  final RfqService service = ref.watch(rfqServiceProvider);
  return service.getRfqById(id);
});

/// Provider for quotations list for a given RFQ ID.
final AutoDisposeFutureProviderFamily<List<Quotation>, int> rfqQuotationsProvider =
    FutureProvider.autoDispose.family<List<Quotation>, int>((Ref ref, int rfqId) async {
  final RfqService service = ref.watch(rfqServiceProvider);
  return service.getQuotationsForRfq(rfqId);
});

/// Async notifier managing Buyer's RFQs (My RFQs).
final AsyncNotifierProvider<MyRfqsNotifier, RfqListResponse> myRfqsProvider =
    AsyncNotifierProvider<MyRfqsNotifier, RfqListResponse>(MyRfqsNotifier.new);

class MyRfqsNotifier extends AsyncNotifier<RfqListResponse> {
  String? _search;
  String? _status;
  int _page = 1;

  @override
  Future<RfqListResponse> build() async {
    final RfqService service = ref.watch(rfqServiceProvider);
    return service.getMyRfqs(
      search: _search,
      status: _status,
      page: _page,
    );
  }

  Future<void> setFilters({String? search, String? status}) async {
    _search = search;
    _status = status;
    _page = 1;
    await refresh();
  }

  Future<void> setPage(int page) async {
    if (page == _page) return;
    _page = page;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue<RfqListResponse>.loading();
    state = await AsyncValue.guard(() async {
      final RfqService service = ref.read(rfqServiceProvider);
      return service.getMyRfqs(
        search: _search,
        status: _status,
        page: _page,
      );
    });
  }

  Future<Rfq> createRfq(CreateRfqRequest request) async {
    final RfqService service = ref.read(rfqServiceProvider);
    final Rfq rfq = await service.createRfq(request);
    await refresh();
    return rfq;
  }

  Future<Rfq> cancelRfq(int rfqId) async {
    final RfqService service = ref.read(rfqServiceProvider);
    final Rfq rfq = await service.cancelRfq(rfqId);
    await refresh();
    ref.invalidate(rfqDetailsProvider(rfqId));
    return rfq;
  }
}

/// Async notifier managing Supplier's Received RFQs.
final AsyncNotifierProvider<ReceivedRfqsNotifier, RfqListResponse>
    receivedRfqsProvider =
    AsyncNotifierProvider<ReceivedRfqsNotifier, RfqListResponse>(
        ReceivedRfqsNotifier.new);

class ReceivedRfqsNotifier extends AsyncNotifier<RfqListResponse> {
  String? _search;
  String? _status;
  int _page = 1;

  @override
  Future<RfqListResponse> build() async {
    final RfqService service = ref.watch(rfqServiceProvider);
    return service.getReceivedRfqs(
      search: _search,
      status: _status,
      page: _page,
    );
  }

  Future<void> setFilters({String? search, String? status}) async {
    _search = search;
    _status = status;
    _page = 1;
    await refresh();
  }

  Future<void> setPage(int page) async {
    if (page == _page) return;
    _page = page;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue<RfqListResponse>.loading();
    state = await AsyncValue.guard(() async {
      final RfqService service = ref.read(rfqServiceProvider);
      return service.getReceivedRfqs(
        search: _search,
        status: _status,
        page: _page,
      );
    });
  }

  Future<Quotation> submitQuotation(int rfqId, SubmitQuotationRequest request) async {
    final RfqService service = ref.read(rfqServiceProvider);
    final Quotation quotation = await service.submitQuotation(rfqId, request);
    await refresh();
    ref.invalidate(rfqDetailsProvider(rfqId));
    ref.invalidate(rfqQuotationsProvider(rfqId));
    return quotation;
  }
}

