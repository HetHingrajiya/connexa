import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/feed/models/feed_models.dart';
import 'package:connexa/features/feed/presentation/widgets/post_card.dart';
import 'package:connexa/features/feed/providers/feed_providers.dart';

class BusinessFeedScreen extends ConsumerStatefulWidget {
  const BusinessFeedScreen({super.key});

  @override
  ConsumerState<BusinessFeedScreen> createState() => _BusinessFeedScreenState();
}

class _BusinessFeedScreenState extends ConsumerState<BusinessFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  static const List<(String, int?)> _filterChips = <(String, int?)>[
    ('All Posts', null),
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final FeedState feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Industrial Community Feed'),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/feed/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Industry Filter Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _filterChips.length,
                separatorBuilder: (BuildContext ctx, int i) => const SizedBox(width: 8),
                itemBuilder: (BuildContext ctx, int i) {
                  final (String label, int? id) = _filterChips[i];
                  final bool isSelected = (id == null && feedState.selectedIndustryId == null) ||
                      (id != null && feedState.selectedIndustryId == id);

                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    onSelected: (_) {
                      ref.read(feedNotifierProvider.notifier).setIndustryFilter(id);
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Main Feed Area
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                if (feedState.isLoading && feedState.posts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (feedState.errorMessage != null && feedState.posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Unable to load feed',
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            feedState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(feedNotifierProvider.notifier)
                                  .loadFeed(refresh: true);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (feedState.posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.dynamic_feed_outlined,
                            size: 56,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No community posts yet',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.brandNavy,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Share plant updates, machinery installations, factory expansions, or product launches with the industrial network.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/feed/create'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(feedNotifierProvider.notifier)
                        .loadFeed(refresh: true);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xxl,
                    ),
                    itemCount: feedState.posts.length +
                        (feedState.isLoadingMore ? 1 : 0),
                    itemBuilder: (BuildContext ctx, int i) {
                      if (i == feedState.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final PostSummary post = feedState.posts[i];
                      return PostCard(
                        post: post,
                        onTap: () => context.push('/feed/posts/${post.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
