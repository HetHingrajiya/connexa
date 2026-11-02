import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/presentation/compare_job_work_quotations_dialog.dart';
import 'package:connexa/features/job_work/presentation/submit_job_work_quotation_sheet.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';

class JobWorkDetailsScreen extends ConsumerStatefulWidget {
  const JobWorkDetailsScreen({
    super.key,
    required this.requirementId,
  });

  final int requirementId;

  @override
  ConsumerState<JobWorkDetailsScreen> createState() =>
      _JobWorkDetailsScreenState();
}

class _JobWorkDetailsScreenState extends ConsumerState<JobWorkDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final JobWorkDetailsState state =
        ref.watch(jobWorkDetailsProvider(widget.requirementId));

    if (state.isLoading && state.requirement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Work Requirement')),
        body: const Center(
          child: AppLoadingIndicator(message: 'Loading requirement details...'),
        ),
      );
    }

    if (state.errorMessage != null && state.requirement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Work Requirement')),
        body: AppErrorState(
          title: 'Failed to load details',
          description: state.errorMessage!,
          onRetry: () => ref
              .read(jobWorkDetailsProvider(widget.requirementId).notifier)
              .loadDetails(),
        ),
      );
    }

    final JobWorkRequirement req = state.requirement!;
    final List<JobWorkQuotation> quotations = state.quotations;

    return Scaffold(
      appBar: AppBar(
        title: Text(req.requirementNumber),
        elevation: 0,
        actions: <Widget>[
          if (req.isOwner && req.status == JobWorkRequirementStatus.open)
            PopupMenuButton<String>(
              onSelected: (String action) async {
                if (action == 'close') {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext ctx) => AlertDialog(
                      title: const Text('Close Requirement'),
                      content: const Text(
                          'Are you sure you want to close this requirement to new quotations?'),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Close')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(jobWorkDetailsProvider(req.id).notifier)
                        .loadDetails();
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'close',
                  child: Text('Close Requirement'),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(jobWorkDetailsProvider(widget.requirementId).notifier)
            .loadDetails(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            // 1. Order active banner (if awarded)
            if (req.activeOrderId != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF059669), size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Job Work Order Active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            'Order #${req.activeOrderNumber ?? ''} has been placed.',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () =>
                          context.push('/job-work-orders/${req.activeOrderId}'),
                      child: const Text('View Order',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 2. Requirement Header Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          req.requirementNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            req.status.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      req.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Owner details
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            req.ownerCompanyName.isNotEmpty
                                ? req.ownerCompanyName[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      req.ownerCompanyName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (req.ownerIsVerified) ...<Widget>[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF0D9488),
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                req.locationSummary,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
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
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Technical Specifications Table
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Technical Specifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildSpecRow('Manufacturing Process', req.jobWorkProcess),
                    if (req.machineType != null && req.machineType!.isNotEmpty)
                      _buildSpecRow('Machine Type', req.machineType!),
                    if (req.requiredMachineCapacity != null &&
                        req.requiredMachineCapacity!.isNotEmpty)
                      _buildSpecRow(
                          'Bed / Envelope Size', req.requiredMachineCapacity!),
                    if (req.requiredTolerance != null &&
                        req.requiredTolerance!.isNotEmpty)
                      _buildSpecRow(
                          'Required Tolerance', req.requiredTolerance!),
                    if (req.materialType != null &&
                        req.materialType!.isNotEmpty)
                      _buildSpecRow('Material Spec', req.materialType!),
                    _buildSpecRow('Material Supply',
                        req.materialResponsibility.label),
                    _buildSpecRow('Required Quantity', req.formattedQuantity),
                    if (req.targetBudget != null)
                      _buildSpecRow(
                          'Target Budget', '₹${req.targetBudget!.toStringAsFixed(2)}'),
                    _buildSpecRow('Location', req.location),
                    if (req.targetCompletionDateUtc != null)
                      _buildSpecRow(
                        'Target Completion',
                        '${req.targetCompletionDateUtc!.day}/${req.targetCompletionDateUtc!.month}/${req.targetCompletionDateUtc!.year}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Description & Scope
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Scope of Work & Notes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 16),
                    Text(
                      req.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                    if (req.deliveryTerms != null &&
                        req.deliveryTerms!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      const Text(
                        'Delivery & Quality Terms:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        req.deliveryTerms!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Drawings & CAD Attachments
            if (req.attachments.isNotEmpty) ...<Widget>[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.attach_file_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Engineering Drawings (${req.attachments.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      ...req.attachments.map((JobWorkAttachment a) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                                Icons.insert_drive_file_outlined,
                                color: AppColors.primary),
                            title: Text(a.originalFileName,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${a.fileExtension.toUpperCase()} • ${a.formattedFileSize}'),
                            trailing: const Icon(Icons.download_rounded,
                                color: AppColors.primary),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Attachment download started: ${a.originalFileName}')),
                              );
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 6. OWNER SECTION: Received Quotations & Comparison
            if (req.isOwner) ...<Widget>[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Received Quotations (${quotations.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (quotations.length >= 2)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.compare_arrows_rounded,
                                  size: 16),
                              label: const Text('Compare',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4338CA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 34),
                              ),
                              onPressed: () =>
                                  CompareJobWorkQuotationsDialog.show(
                                context,
                                requirement: req,
                                quotations: quotations,
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (quotations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No quotations received yet.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...quotations.map((JobWorkQuotation q) =>
                            _buildQuotationCardForOwner(req, q)),
                    ],
                  ),
                ),
              ),
            ],

            // 7. CONTRACTOR SECTION: Submit / View Quote CTA
            if (!req.isOwner) ...<Widget>[
              if (req.hasQuoted) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: const <Widget>[
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF15803D), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'You have submitted a quotation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The requirement owner is reviewing your proposal. You will be notified when a decision is made.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ] else if (req.status == JobWorkRequirementStatus.open) ...<Widget>[
                AppButton.primary(
                  text: 'Submit Quotation for this Job Work',
                  height: 48,
                  onPressed: () => SubmitJobWorkQuotationSheet.show(context, req),
                ),
              ] else ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'This job work requirement is closed to new quotations.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCardForOwner(
      JobWorkRequirement req, JobWorkQuotation q) {
    final bool canDecide = req.status == JobWorkRequirementStatus.open &&
        (q.status == JobWorkQuotationStatus.submitted ||
            q.status == JobWorkQuotationStatus.revisionRequested);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    q.contractorCompanyName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  if (q.contractorIsVerified) ...<Widget>[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF0D9488), size: 14),
                  ],
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: q.status == JobWorkQuotationStatus.accepted
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  q.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: q.status == JobWorkQuotationStatus.accepted
                        ? const Color(0xFF15803D)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                q.formattedTotal,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Rate: ${q.formattedOfferedRate} • Lead: ${q.leadTimeFormatted}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF475569)),
              ),
            ],
          ),
          if (q.machineProposed != null && q.machineProposed!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Machine: ${q.machineProposed!}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
          if (canDecide) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () async {
                    final TextEditingController reasonCtrl =
                        TextEditingController();
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext ctx) => AlertDialog(
                        title: const Text('Reject Quotation'),
                        content: TextField(
                          controller: reasonCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Reason for rejection',
                            hintText: 'e.g., Price too high, capacity issue',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Reject')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(jobWorkDetailsProvider(req.id).notifier)
                          .decideQuotation(
                            quotationId: q.id,
                            decision: 'reject',
                            notes: reasonCtrl.text.trim(),
                          );
                    }
                  },
                  child: const Text('Reject',
                      style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext ctx) => AlertDialog(
                        title: const Text('Accept Quotation'),
                        content: Text(
                            'Accept quotation from ${q.contractorCompanyName} for ${q.formattedTotal} and generate Job Work Order?'),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Accept & Place Order')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(jobWorkDetailsProvider(req.id).notifier)
                          .decideQuotation(
                            quotationId: q.id,
                            decision: 'accept',
                          );
                    }
                  },
                  child: const Text('Accept Quote',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

