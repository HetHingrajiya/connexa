import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/feed/models/feed_models.dart';
import 'package:connexa/features/feed/providers/feed_providers.dart';
import 'package:connexa/features/feed/services/feed_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({
    super.key,
    this.editPostId,
  });

  final int? editPostId;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final List<String> _attachmentUrls = <String>[];

  int? _selectedIndustryId;
  bool _isLoading = false;
  bool _isInitLoading = false;

  static const List<(String, int?)> _industries = <(String, int?)>[
    ('General / All Industries', null),
    ('Industrial Machinery', 1),
    ('Metal & Fabrication', 2),
    ('Electrical & Automation', 3),
    ('Automotive & Spares', 4),
    ('Textile & Processing', 5),
    ('Chemicals & Plastics', 6),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editPostId != null) {
      _loadExistingPost();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPost() async {
    setState(() => _isInitLoading = true);
    try {
      final FeedService service = ref.read(feedServiceProvider);
      final PostSummary post = await service.getPostById(widget.editPostId!);
      if (mounted) {
        _contentController.text = post.content;
        _selectedIndustryId = post.industryId;
        _attachmentUrls.addAll(post.attachments.map((PostAttachment a) => a.mediaUrl));
        setState(() => _isInitLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load post: $e')),
        );
      }
    }
  }

  void _addMediaUrl() {
    final String url = _imageUrlController.text.trim();
    if (url.isNotEmpty && !_attachmentUrls.contains(url)) {
      setState(() {
        _attachmentUrls.add(url);
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final FeedService service = ref.read(feedServiceProvider);

      if (widget.editPostId != null) {
        final PostSummary updated = await service.updatePost(
          widget.editPostId!,
          UpdatePostRequest(
            content: _contentController.text.trim(),
            industryId: _selectedIndustryId,
          ),
        );
        ref.read(feedNotifierProvider.notifier).addOrUpdatePost(updated);
      } else {
        final PostSummary created = await service.createPost(
          CreatePostRequest(
            content: _contentController.text.trim(),
            industryId: _selectedIndustryId,
            attachmentUrls: _attachmentUrls.isNotEmpty ? _attachmentUrls : null,
          ),
        );
        ref.read(feedNotifierProvider.notifier).addOrUpdatePost(created);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editPostId != null
                ? 'Post updated successfully!'
                : 'Post published to the industrial community!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final bool isEdit = widget.editPostId != null;

    if (_isInitLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Post' : 'Create Post'),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'Save' : 'Publish',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Industry Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedIndustryId,
                    isExpanded: true,
                    hint: const Text('Select Industry Sector (Optional)'),
                    items: _industries.map(((String, int?) item) {
                      return DropdownMenuItem<int?>(
                        value: item.$2,
                        child: Text(item.$1, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() => _selectedIndustryId = value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Post Content Input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextFormField(
                  controller: _contentController,
                  maxLines: 7,
                  minLines: 4,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText:
                        'Share equipment showcases, machinery capabilities, factory expansions, certifications or industrial achievements...',
                    border: InputBorder.none,
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter post content.';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Attachments Section
              if (!isEdit) ...<Widget>[
                Text(
                  'Media Attachments (Optional Image URLs)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _imageUrlController,
                        style: AppTextStyles.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/machine-image.jpg',
                          hintStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _addMediaUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                if (_attachmentUrls.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachmentUrls.map((String url) {
                      return Chip(
                        label: Text(
                          url.length > 28 ? '${url.substring(0, 25)}...' : url,
                          style: AppTextStyles.labelSmall,
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _attachmentUrls.remove(url));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.xl),

              // B2B Community guidelines reminder
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryActionContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: AppColors.primaryAction,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Connexa is a verified industrial network. Please post professional, authentic, and compliant business updates only.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.brandNavy,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
