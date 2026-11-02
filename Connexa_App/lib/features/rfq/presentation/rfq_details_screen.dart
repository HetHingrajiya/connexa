import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/presentation/submit_quotation_sheet.dart';
import 'package:connexa/features/rfq/providers/rfq_provider.dart';
import 'package:connexa/features/rfq/services/rfq_service.dart';
import 'package:connexa/features/orders/presentation/order_dialogs.dart';

/// Comprehensive screen displaying full RFQ details, quotation history, version comparison, and decision actions.
class RfqDetailsScreen extends ConsumerStatefulWidget {
  const RfqDetailsScreen({
    super.key,
    required this.rfqId,
    this.initialRfq,
  });

  final int rfqId;
  final Rfq? initialRfq;

  @override
  ConsumerState<RfqDetailsScreen> createState() => _RfqDetailsScreenState();
}

class _RfqDetailsScreenState extends ConsumerState<RfqDetailsScreen> {
  bool _isProcessingAction = false;

  Future<void> _refresh() async {
    ref.invalidate(rfqDetailsProvider(widget.rfqId));
    ref.invalidate(rfqQuotationsProvider(widget.rfqId));
  }

  Widget _buildRfqStatusBadge(RfqStatus status) {
    switch (status) {
      case RfqStatus.open:
        return const AppBadge(
          label: 'Open',
          variant: AppBadgeVariant.primary,
        );
      case RfqStatus.quotationReceived:
        return const AppBadge(
          label: 'Quote Received',
          variant: AppBadgeVariant.secondary,
        );
      case RfqStatus.closed:
        return const AppBadge(
          label: 'Closed / Accepted',
          variant: AppBadgeVariant.success,
        );
      case RfqStatus.cancelled:
        return const AppBadge(
          label: 'Cancelled',
          variant: AppBadgeVariant.neutral,
        );
    }
  }

  Widget _buildQuotationStatusBadge(Quotation quotation) {
    if (quotation.isExpired || quotation.validUntilUtc.isBefore(DateTime.now())) {
      return const AppBadge(
        label: 'Expired',
        variant: AppBadgeVariant.neutral,
      );
    }

    switch (quotation.status) {
      case QuotationStatus.draft:
        return const AppBadge(
          label: 'Draft',
          variant: AppBadgeVariant.neutral,
        );
      case QuotationStatus.submitted:
        return const AppBadge(
          label: 'Active Quote',
          variant: AppBadgeVariant.primary,
        );
      case QuotationStatus.revised:
        return AppBadge(
          label: 'Superseded (v${quotation.version})',
          variant: AppBadgeVariant.neutral,
        );
      case QuotationStatus.accepted:
        return const AppBadge(
          label: 'Accepted',
          variant: AppBadgeVariant.success,
        );
      case QuotationStatus.rejected:
        return const AppBadge(
          label: 'Rejected',
          variant: AppBadgeVariant.error,
        );
      case QuotationStatus.expired:
        return const AppBadge(
          label: 'Expired',
          variant: AppBadgeVariant.neutral,
        );
    }
  }

  Future<void> _handleDecideQuotation({
    required Quotation quotation,
    required String decision, // 'Accept', 'Reject', 'RequestRevision'
  }) async {
    String? reasonNotes;

    if (decision == 'Reject') {
      final TextEditingController reasonController = TextEditingController();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Reject Quotation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Please state the reason for rejecting this quotation:'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('rejectionReasonInput'),
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Price too high, lead time too long...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirmRejectButton'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reject Quote', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      reasonNotes = reasonController.text.trim();
    } else if (decision == 'RequestRevision') {
      final TextEditingController notesController = TextEditingController();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Request Quote Revision'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Explain what changes or discounts you are requesting:'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('revisionNotesInput'),
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Please reduce shipping costs or match unit price ₹120...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirmRevisionButton'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      reasonNotes = notesController.text.trim();
    } else if (decision == 'Accept') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Accept Quotation'),
          content: Text(
            'Are you sure you want to accept quotation #${quotation.quotationNumber} for a total of ₹${quotation.totalAmount.toStringAsFixed(2)}?\n\nThis will mark the RFQ as closed and notify the supplier.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirmAcceptButton'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Accept Quote', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final RfqService service = ref.read(rfqServiceProvider);
      await service.decideQuotation(
        quotation.id,
        DecideQuotationRequest(decision: decision, notes: reasonNotes),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'Accept'
                  ? 'Quotation accepted successfully!'
                  : decision == 'Reject'
                      ? 'Quotation rejected.'
                      : 'Revision requested from supplier.',
            ),
            backgroundColor: decision == 'Accept'
                ? AppColors.success
                : decision == 'Reject'
                    ? AppColors.error
                    : AppColors.primary,
          ),
        );
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  Future<void> _handleCancelRfq(Rfq rfq) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cancel RFQ'),
        content: const Text(
          'Are you sure you want to cancel this Request for Quotation? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            key: const Key('confirmCancelRfqButton'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel RFQ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      await ref.read(myRfqsProvider.notifier).cancelRfq(rfq.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RFQ cancelled.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  Future<void> _openCreateOrderSheet(Rfq rfq, Quotation quotation) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => CreateOrderSheet(
        quotationId: quotation.id,
        quotationNumber: quotation.quotationNumber,
        productName: rfq.productName,
        quantity: quotation.quantity,
        unitOfMeasurement: rfq.unitOfMeasurement,
        unitPrice: quotation.unitPrice,
        subtotal: quotation.subtotal,
        taxRatePercent: quotation.taxRatePercent,
        taxAmount: quotation.taxAmount,
        shippingCharges: quotation.shippingCharges,
        totalAmount: quotation.totalAmount,
        initialDeliveryAddress: rfq.deliveryLocation,
        initialLeadTime: quotation.estimatedDeliveryTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Rfq> rfqAsync = ref.watch(rfqDetailsProvider(widget.rfqId));
    final AsyncValue<List<Quotation>> quotesAsync =
        ref.watch(rfqQuotationsProvider(widget.rfqId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          rfqAsync.value?.rfqNumber ?? 'RFQ Details',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: <Widget>[
          if (rfqAsync.value != null &&
              rfqAsync.value!.isBuyer &&
              rfqAsync.value!.isOpen) ...<Widget>[
            IconButton(
              key: const Key('cancelRfqMenuButton'),
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              tooltip: 'Cancel RFQ',
              onPressed: _isProcessingAction
                  ? null
                  : () => _handleCancelRfq(rfqAsync.value!),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: rfqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace? stack) => Center(
          child: AppErrorState(
            title: 'Failed to load RFQ',
            description: err.toString().replaceFirst('Exception: ', ''),
            onRetry: _refresh,
          ),
        ),
        data: (Rfq rfq) {
          final List<Quotation> quotes = quotesAsync.value ?? <Quotation>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Top Overview Card
                  _buildOverviewCard(rfq),
                  const SizedBox(height: 16),

                  // Specifications Card
                  _buildSpecificationsCard(rfq),
                  const SizedBox(height: 20),

                  // Quotations & Revisions Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.receipt_long_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Quotations & Revisions (${quotes.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (rfq.isSupplier && rfq.isOpen) ...<Widget>[
                        TextButton.icon(
                          key: const Key('submitQuoteHeaderButton'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            quotes.isEmpty ? 'Submit Quote' : 'New Revision',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => SubmitQuotationSheet.show(
                            context,
                            rfq: rfq,
                            onQuotationSubmitted: (_) => _refresh(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quotation Cards List
                  if (quotes.isEmpty) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: <Widget>[
                            const Icon(Icons.pending_actions_rounded,
                                size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text(
                              'Awaiting Supplier Quotation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rfq.isSupplier
                                  ? 'Click below to submit your commercial quotation.'
                                  : 'The supplier has received your RFQ and will submit a formal quote soon.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...<Widget>[
                    ...quotes.map((Quotation q) => _buildQuotationCard(
                          quotation: q,
                          rfq: rfq,
                        )),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      bottomSheet: rfqAsync.value != null &&
              rfqAsync.value!.isSupplier &&
              rfqAsync.value!.isOpen
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('submitQuotationBottomCta'),
                  onPressed: () => SubmitQuotationSheet.show(
                    context,
                    rfq: rfqAsync.value!,
                    onQuotationSubmitted: (_) => _refresh(),
                  ),
                  icon: const Icon(Icons.local_offer_rounded, size: 20),
                  label: Text(
                    (quotesAsync.value?.isNotEmpty ?? false)
                        ? 'Submit Revised Quotation (v${(quotesAsync.value?.length ?? 0) + 1})'
                        : 'Submit Quotation',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOverviewCard(Rfq rfq) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  rfq.rfqNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                _buildRfqStatusBadge(rfq.status),
              ],
            ),
            const SizedBox(height: 12),
            // Product info
            InkWell(
              onTap: () => context.push('/products/${rfq.productId}'),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          rfq.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'View Product Details →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            // Buyer & Supplier details
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Buyer Company',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rfq.buyerCompanyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Supplier Company',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rfq.supplierCompanyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationsCard(Rfq rfq) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'RFQ Requirements',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildSpecItem(
                    label: 'Requested Quantity',
                    value: '${rfq.quantity.toStringAsFixed(0)} ${rfq.unitOfMeasurement}',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                ),
                Expanded(
                  child: _buildSpecItem(
                    label: 'Target Unit Price',
                    value: rfq.targetPrice != null
                        ? '₹ ${rfq.targetPrice!.toStringAsFixed(2)}'
                        : 'Open / Not specified',
                    icon: Icons.currency_rupee_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildSpecItem(
                    label: 'Required By Date',
                    value: rfq.requiredDeliveryDateUtc != null
                        ? formatRfqDate(rfq.requiredDeliveryDateUtc)
                        : 'Flexible',
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                Expanded(
                  child: _buildSpecItem(
                    label: 'Delivery Location',
                    value: rfq.deliveryLocation,
                    icon: Icons.location_on_outlined,
                  ),
                ),
              ],
            ),
            if (rfq.additionalSpecifications != null &&
                rfq.additionalSpecifications!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Additional Specifications:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rfq.additionalSpecifications!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ],
            if (rfq.attachmentUrl != null && rfq.attachmentUrl!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Icon(Icons.attachment_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Attachment: ${rfq.attachmentUrl}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationCard({
    required Quotation quotation,
    required Rfq rfq,
  }) {
    final bool canDecide = rfq.isBuyer && quotation.canBeDecided && rfq.isOpen;

    return Card(
      key: Key('quotationCard_${quotation.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: quotation.status == QuotationStatus.accepted
              ? AppColors.success
              : quotation.status == QuotationStatus.submitted
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
          width: quotation.status == QuotationStatus.accepted ? 2 : 1,
        ),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Quotation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Version ${quotation.version}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quotation.quotationNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildQuotationStatusBadge(quotation),
              ],
            ),
            const SizedBox(height: 12),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Unit Price: ₹${quotation.unitPrice.toStringAsFixed(2)} × ${quotation.quantity.toStringAsFixed(0)} ${rfq.unitOfMeasurement}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '₹ ${quotation.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Tax (${quotation.taxRatePercent}%):',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '₹ ${quotation.taxAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Shipping Charges:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '₹ ${quotation.shippingCharges.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        '₹ ${quotation.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Lead Time & Validity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Lead Time: ${quotation.estimatedDeliveryTime}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Valid Until: ${formatRfqDate(quotation.validUntilUtc)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: quotation.validUntilUtc.isBefore(DateTime.now())
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontWeight: quotation.validUntilUtc.isBefore(DateTime.now())
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),

            if (quotation.termsAndConditions != null &&
                quotation.termsAndConditions!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Terms: ${quotation.termsAndConditions}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],

            if (quotation.rejectionReason != null &&
                quotation.rejectionReason!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Rejection Reason: ${quotation.rejectionReason}',
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (quotation.revisionNotes != null &&
                quotation.revisionNotes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Revision Requested: ${quotation.revisionNotes}',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Buyer Decision Actions
            if (canDecide) ...<Widget>[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: Key('rejectQuoteBtn_${quotation.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isProcessingAction
                          ? null
                          : () => _handleDecideQuotation(
                                quotation: quotation,
                                decision: 'Reject',
                              ),
                      child: const Text('Reject', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: Key('requestRevisionBtn_${quotation.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isProcessingAction
                          ? null
                          : () => _handleDecideQuotation(
                                quotation: quotation,
                                decision: 'RequestRevision',
                              ),
                      child: const Text('Revise', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      key: Key('acceptQuoteBtn_${quotation.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isProcessingAction
                          ? null
                          : () => _handleDecideQuotation(
                                quotation: quotation,
                                decision: 'Accept',
                              ),
                      child: const Text('Accept',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],

            // Buyer Create Order Action (when Quotation is Accepted and current user is Buyer)
            if (quotation.status == QuotationStatus.accepted && rfq.isBuyer) ...<Widget>[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: Key('createOrderFromQuotationBtn_${quotation.id}'),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isProcessingAction
                      ? null
                      : () => _openCreateOrderSheet(rfq, quotation),
                  label: const Text(
                    'Place Order from this Quotation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
