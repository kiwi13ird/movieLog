import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  void _feedback(BuildContext context, MyRatingsViewModel vm) {
    if (context.mounted && vm.feedback != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.feedback!)));
    }
  }

  Future<void> _edit(
    BuildContext context,
    MyRatingsViewModel vm,
    RatingWithMovie entry,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: entry.rating.score,
        initialComment: entry.rating.comment,
        onSubmit: (score, comment) => vm.updateRating(
          ratingId: entry.rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (context.mounted && saved == true) _feedback(context, vm);
  }

  Future<void> _delete(
    BuildContext context,
    MyRatingsViewModel vm,
    int id,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteRatingDialog(onConfirm: () => vm.deleteRating(id)),
    );
    if (context.mounted && deleted == true) _feedback(context, vm);
  }

  Future<void> _deleteSelected(
    BuildContext context,
    MyRatingsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('${vm.selectedRatingIds.length}개 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('bulkDeleteConfirmButton'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    await vm.deleteSelected();
    if (context.mounted) _feedback(context, vm);
  }

  @override
  Widget build(BuildContext context) => Consumer<MyRatingsViewModel>(
    builder: (context, vm, child) => PopScope(
      canPop: !vm.busy,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: !vm.editing,
          title: Text(
            vm.editing ? '${vm.selectedRatingIds.length}개 선택' : '내가 등록한 평점',
          ),
          leading: BackButton(
            key: const Key('ratingsBackButton'),
            onPressed: vm.busy ? null : () => context.pop(),
          ),
          actions: [
            if (vm.canManage && vm.ratings.isNotEmpty)
              TextButton(
                key: const Key('ratingsEditModeButton'),
                onPressed: vm.busy || vm.isRefreshing ? null : vm.toggleEditing,
                child: Text(vm.editing ? '취소' : '편집'),
              ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Text(
                      '학습용 회원 #${vm.memberId}의 평점 · 로그인 인증 전 단계',
                      style: const TextStyle(color: Color(0xFF777183)),
                    ),
                  ),
                  if (vm.isRefreshing) const LinearProgressIndicator(),
                  if (vm.refreshError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            vm.refreshError!,
                            key: const Key('ratingsRefreshError'),
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton(
                            key: const Key('ratingsGetRetryButton'),
                            onPressed: vm.busy || vm.isRefreshing
                                ? null
                                : vm.load,
                            child: const Text('목록 조회만 다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: switch (vm.status) {
                      MyRatingsLoadStatus.idle ||
                      MyRatingsLoadStatus.loading => const Center(
                        key: Key('ratingsLoading'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('평점을 불러오는 중이에요.'),
                          ],
                        ),
                      ),
                      MyRatingsLoadStatus.empty => const Center(
                        key: Key('ratingsEmpty'),
                        child: Text('등록된 평점이 없습니다.'),
                      ),
                      MyRatingsLoadStatus.error => Center(
                        key: const Key('ratingsError'),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(vm.message ?? '평점을 불러오지 못했습니다.'),
                              const SizedBox(height: 16),
                              MovieLogButton(
                                label: '다시 시도',
                                onPressed: vm.load,
                              ),
                            ],
                          ),
                        ),
                      ),
                      MyRatingsLoadStatus.success => ListView.separated(
                        key: const Key('ratingsSuccess'),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount:
                            vm.ratings.length + (vm.message != null ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (vm.message != null && index == 0) {
                            return Text(vm.message!);
                          }
                          final entry =
                              vm.ratings[index - (vm.message != null ? 1 : 0)];
                          return _RatingCard(
                            entry: entry,
                            editing: vm.editing,
                            selected: vm.selectedRatingIds.contains(
                              entry.rating.ratingId,
                            ),
                            onSelected: () =>
                                vm.toggleSelection(entry.rating.ratingId),
                            onEdit: vm.canManage && !vm.busy && !vm.isRefreshing
                                ? () => _edit(context, vm, entry)
                                : null,
                            onDelete:
                                vm.canManage && !vm.busy && !vm.isRefreshing
                                ? () => _delete(
                                    context,
                                    vm,
                                    entry.rating.ratingId,
                                  )
                                : null,
                          );
                        },
                      ),
                    },
                  ),
                  if (vm.editing)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: MovieLogButton(
                        key: const Key('bulkDeleteButton'),
                        label: '선택한 ${vm.selectedRatingIds.length}개 삭제',
                        width: double.infinity,
                        onPressed:
                            vm.selectedRatingIds.isNotEmpty &&
                                !vm.busy &&
                                !vm.isRefreshing
                            ? () => _deleteSelected(context, vm)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            if (vm.busy)
              const Positioned.fill(
                child: Stack(
                  key: Key('ratingsWriteOverlay'),
                  children: [
                    ModalBarrier(dismissible: false, color: Color(0x66000000)),
                    Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('처리 중입니다. 잠시 기다려 주세요.'),
                            ],
                          ),
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.editing,
    required this.selected,
    required this.onSelected,
    this.onEdit,
    this.onDelete,
  });
  final RatingWithMovie entry;
  final bool editing;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) {
    final r = entry.rating;
    final movie = entry.movie;
    final d = r.createdAt.toLocal();
    return Card(
      key: ValueKey('rating-${r.ratingId}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie != null)
                  MoviePoster(
                    movie: movie.toMovie(const []),
                    width: 64,
                    height: 92,
                  )
                else
                  Container(
                    width: 64,
                    height: 92,
                    color: const Color(0xFFECE8F5),
                    child: const Icon(Icons.movie_creation_outlined),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie?.title ?? '영화 정보를 불러올 수 없어요',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '영화 ID ${r.movieId}',
                        style: const TextStyle(
                          color: Color(0xFF777183),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '★ ${r.score} / 5',
                        style: const TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (r.comment != null) ...[
                        const SizedBox(height: 8),
                        Text(r.comment!),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777183),
                        ),
                      ),
                    ],
                  ),
                ),
                if (editing)
                  Checkbox(
                    key: ValueKey('select-rating-${r.ratingId}'),
                    value: selected,
                    onChanged: (_) => onSelected(),
                  ),
              ],
            ),
            if (!editing && (onEdit != null || onDelete != null))
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: ValueKey('edit-rating-${r.ratingId}'),
                    onPressed: onEdit,
                    child: const Text('수정'),
                  ),
                  TextButton(
                    key: ValueKey('delete-rating-${r.ratingId}'),
                    onPressed: onDelete,
                    child: const Text('삭제'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
