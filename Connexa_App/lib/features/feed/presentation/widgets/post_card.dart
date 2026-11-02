import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/feed/models/feed_models.dart';
import 'package:connexa/features/feed/presentation/widgets/report_content_dialog.dart';
import 'package:connexa/features/feed/providers/feed_providers.dart';

class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  final PostSummary post;
  final VoidCallback? onTap;

  String _formatRelativeTime(DateTime dateTime) {
    final Duration diff = DateTime.now().toUtc().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _handleShare(BuildContext context) {
    final String shareText =
        '${post.displayName} on Connexa:\n"${post.content}"\nhttps://connexa.app/feed/${post.id}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
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
      final bool success =
          await ref.read(feedNotifierProvider.notifier).deletePost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Post deleted.' : 'Failed to delete post.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Author header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandNavyLight,
                    backgroundImage: (post.authorAvatarUrl != null &&
                            post.authorAvatarUrl!.isNotEmpty)
                        ? NetworkImage(post.authorAvatarUrl!)
                        : null,
                    child: (post.authorAvatarUrl == null ||
                            post.authorAvatarUrl!.isEmpty)
                        ? Text(
                            post.displayName.isNotEmpty
                                ? post.displayName[0].toUpperCase()
                                : 'C',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
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
                                post.displayName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isVerifiedBusiness) ...<Widget>[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            if (post.industryName != null) ...<Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  post.industryName!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              _formatRelativeTime(post.createdAtUtc),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (post.isEdited) ...<Widget>[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                    onSelected: (String value) {
                      if (value == 'edit') {
                        context.push('/feed/edit/${post.id}');
                      } else if (value == 'delete') {
                        _handleDelete(context, ref);
                      } else if (value == 'report') {
                        ReportContentDialog.show(context, postId: post.id).then((bool? res) {
                          if (res == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted. Thank you for keeping Connexa safe.')),
                            );
                          }
                        });
                      }
                    },
                    itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                      if (post.isAuthor) ...<PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Post'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete Post', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ] else ...<PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
                              SizedBox(width: 8),
                              Text('Report Post'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Post text content
              Text(
                post.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),

              // Attachments preview
              if (post.attachments.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.attachments.first.mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext ctx, Object err, StackTrace? st) {
                        return Container(
                          color: AppColors.surfaceContainer,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.xs),

              // Interaction buttons: Like, Comment, Share
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  // Like
                  InkWell(
                    onTap: () {
                      ref.read(feedNotifierProvider.notifier).toggleLike(post.id);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            post.isLikedByCurrentUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: post.isLikedByCurrentUser
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.likeCount > 0 ? '${post.likeCount}' : 'Like',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: post.isLikedByCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: post.isLikedByCurrentUser
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Comment
                  InkWell(
                    onTap: onTap ?? () => context.push('/feed/posts/${post.id}'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.commentCount > 0
                                ? '${post.commentCount}'
                                : 'Comment',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Share
                  InkWell(
                    onTap: () => _handleShare(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.share_outlined,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Share',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
