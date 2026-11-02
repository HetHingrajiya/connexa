import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/feed/models/feed_models.dart';
import 'package:connexa/features/feed/services/feed_service.dart';

class ReportContentDialog extends ConsumerStatefulWidget {
  const ReportContentDialog({
    super.key,
    this.postId,
    this.commentId,
  }) : assert(postId != null || commentId != null);

  final int? postId;
  final int? commentId;

  static Future<bool?> show(
    BuildContext context, {
    int? postId,
    int? commentId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => ReportContentDialog(
        postId: postId,
        commentId: commentId,
      ),
    );
  }

  @override
  ConsumerState<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends ConsumerState<ReportContentDialog> {
  static const List<String> _reasons = <String>[
    'Spam or Promotional Abuse',
    'Inappropriate / Off-Topic Content',
    'Misleading Specifications or Prices',
    'Harassment or Impersonation',
    'Fake Business Entity',
    'Other Issue',
  ];

  String _selectedReason = _reasons.first;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      final FeedService service = ref.read(feedServiceProvider);
      final bool success = await service.reportContent(
        postId: widget.postId,
        commentId: widget.commentId,
        request: ReportContentRequest(
          reason: _selectedReason,
          details: _detailsController.text.trim().isNotEmpty
              ? _detailsController.text.trim()
              : null,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.postId != null ? 'Report Post' : 'Report Comment',
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.brandNavy),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Help us maintain a trustworthy industrial community. Why are you reporting this?',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._reasons.map((String reason) {
              final bool isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Provide context for the moderation team...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
