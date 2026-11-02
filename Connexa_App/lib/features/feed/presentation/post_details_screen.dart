import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/feed/models/feed_models.dart';
import 'package:connexa/features/feed/presentation/widgets/post_card.dart';
import 'package:connexa/features/feed/presentation/widgets/report_content_dialog.dart';
import 'package:connexa/features/feed/providers/feed_providers.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({
    super.key,
    required this.postId,
  });

  final int postId;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final Duration diff = DateTime.now().toUtc().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _handleSendComment() async {
    final String text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    final PostComment? created = await ref
        .read(postCommentsProvider(widget.postId).notifier)
        .addComment(text);

    if (created != null) {
      // Scroll to bottom of list
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleDeleteComment(int commentId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(postCommentsProvider(widget.postId).notifier)
          .deleteComment(commentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PostSummary> postAsync =
        ref.watch(postDetailsProvider(widget.postId));
    final PostCommentsState commentsState =
        ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Discussion'),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: postAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text('Failed to load post', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(err.toString(), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (PostSummary post) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(postDetailsProvider(widget.postId));
                    await ref
                        .read(postCommentsProvider(widget.postId).notifier)
                        .loadComments();
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: <Widget>[
                      // Main Post Card
                      PostCard(post: post),

                      // Comments header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          'Comments (${commentsState.comments.length})',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandNavy,
                          ),
                        ),
                      ),

                      if (commentsState.isLoading &&
                          commentsState.comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (commentsState.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              'No comments yet. Start the conversation!',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        ...commentsState.comments.map((PostComment comment) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.brandNavyLight,
                                      backgroundImage:
                                          (comment.authorAvatarUrl != null &&
                                                  comment.authorAvatarUrl!.isNotEmpty)
                                              ? NetworkImage(comment.authorAvatarUrl!)
                                              : null,
                                      child: (comment.authorAvatarUrl == null ||
                                              comment.authorAvatarUrl!.isEmpty)
                                          ? Text(
                                              comment.displayName.isNotEmpty
                                                  ? comment.displayName[0]
                                                      .toUpperCase()
                                                  : 'M',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Flexible(
                                                child: Text(
                                                  comment.displayName,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (comment.isVerifiedBusiness) ...<Widget>[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.verified,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            _formatRelativeTime(
                                                comment.createdAtUtc),
                                            style: AppTextStyles.labelSmall.copyWith(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (comment.isAuthor)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            _handleDeleteComment(comment.id),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.flag_outlined,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () {
                                          ReportContentDialog.show(
                                            context,
                                            commentId: comment.id,
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Text(
                                    comment.content,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),

          // Pinned bottom comment composer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: AppTextStyles.bodyMedium,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Write a professional comment...',
                        hintStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendComment(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: commentsState.isSubmitting
                        ? null
                        : _handleSendComment,
                    icon: commentsState.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.primary,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
