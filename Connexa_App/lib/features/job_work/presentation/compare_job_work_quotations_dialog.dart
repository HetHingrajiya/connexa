import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';

class CompareJobWorkQuotationsDialog extends ConsumerStatefulWidget {
  const CompareJobWorkQuotationsDialog({
    super.key,
    required this.requirement,
    required this.quotations,
  });

  final JobWorkRequirement requirement;
  final List<JobWorkQuotation> quotations;

  static Future<void> show(
    BuildContext context, {
    required JobWorkRequirement requirement,
    required List<JobWorkQuotation> quotations,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => CompareJobWorkQuotationsDialog(
        requirement: requirement,
        quotations: quotations,
      ),
    );
  }

  @override
  ConsumerState<CompareJobWorkQuotationsDialog> createState() =>
      _CompareJobWorkQuotationsDialogState();
}

class _CompareJobWorkQuotationsDialogState
    extends ConsumerState<CompareJobWorkQuotationsDialog> {
  int? _acceptingQuoteId;

  Future<void> _acceptQuotation(JobWorkQuotation quote) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirm Quotation Acceptance'),
        content: Text(
          'Are you sure you want to accept the quotation from ${quote.contractorCompanyName} for ${quote.formattedTotal}?\n\nThis will automatically:\n• Award the job work contract\n• Generate Job Work Order\n• Close this requirement\n• Reject competing quotations',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept & Place Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _acceptingQuoteId = quote.id);

    final bool success = await ref
        .read(jobWorkDetailsProvider(widget.requirement.id).notifier)
        .decideQuotation(
          quotationId: quote.id,
          decision: 'accept',
        );

    if (mounted) {
      setState(() => _acceptingQuoteId = null);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quotation accepted! Job Work Order generated for ${quote.contractorCompanyName}.'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<JobWorkQuotation> activeQuotes = widget.quotations
        .where((JobWorkQuotation q) =>
            q.status == JobWorkQuotationStatus.submitted ||
            q.status == JobWorkQuotationStatus.revisionRequested)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Quotation Comparison Matrix',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Comparing ${activeQuotes.length} quotations for ${widget.requirement.title}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),

            if (activeQuotes.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No active quotations available to compare.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeQuotes.length,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final JobWorkQuotation q = activeQuotes[index];
                    final bool isLowestPrice = index == 0; // sorted by totalAmount asc
                    final bool isAccepting = _acceptingQuoteId == q.id;

                    return Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLowestPrice
                              ? const Color(0xFF22C55E)
                              : AppColors.border,
                          width: isLowestPrice ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (isLowestPrice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '★ LOWEST OFFER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),

                          // Contractor & Verified badge
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  q.contractorCompanyName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (q.contractorIsVerified)
                                const Icon(Icons.verified_rounded,
                                    color: Color(0xFF0D9488), size: 16),
                            ],
                          ),
                          Text(
                            q.contractorCity != null
                                ? '${q.contractorCity}, ${q.contractorState ?? ''}'
                                : 'Contractor',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Divider(height: 16),

                          // Total & Unit Rate
                          Text(
                            q.formattedTotal,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Rate: ${q.formattedOfferedRate} / unit',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 12),

                          // Key metrics table
                          _buildComparisonRow(
                            'Lead Time:',
                            q.leadTimeFormatted,
                            Icons.schedule_rounded,
                          ),
                          const SizedBox(height: 6),
                          _buildComparisonRow(
                            'Machine:',
                            q.machineProposed ?? 'Not specified',
                            Icons.precision_manufacturing_outlined,
                          ),
                          const SizedBox(height: 6),
                          _buildComparisonRow(
                            'GST:',
                            '${q.taxRatePercent.toStringAsFixed(0)}% (₹${q.taxAmount.toStringAsFixed(2)})',
                            Icons.receipt_outlined,
                          ),
                          if (q.otherCharges > 0) ...<Widget>[
                            const SizedBox(height: 6),
                            _buildComparisonRow(
                              'Tooling/Other:',
                              '₹${q.otherCharges.toStringAsFixed(2)}',
                              Icons.build_outlined,
                            ),
                          ],
                          const SizedBox(height: 12),

                          if (q.technicalRemarks != null &&
                              q.technicalRemarks!.isNotEmpty) ...<Widget>[
                            const Text(
                              'Remarks:',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              q.technicalRemarks!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF334155)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const Spacer(),

                          // Accept CTA
                          AppButton.primary(
                            text: 'Accept This Quote',
                            height: 38,
                            isLoading: isAccepting,
                            onPressed: isAccepting
                                ? null
                                : () => _acceptQuotation(q),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, IconData icon) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

