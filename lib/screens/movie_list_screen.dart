import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_view_models.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});
  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  MovieListViewModel? _vm;
  int _seenFailure = 0;
  bool _dialogOpen = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MovieListViewModel>();
    if (identical(vm, _vm)) return;
    _vm?.removeListener(_onChange);
    _vm = vm;
    _seenFailure = vm.failureVersion;
    vm.addListener(_onChange);
  }

  void _onChange() {
    final vm = _vm!;
    if (vm.failureVersion == _seenFailure) return;
    _seenFailure = vm.failureVersion;
    if (_dialogOpen || vm.movies.isEmpty) return;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('영화를 불러오지 못했어요'),
          content: const Text('최근에 불러온 목록은 유지했어요. 연결을 확인하고 다시 시도해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      if (mounted && retry == true) await vm.load();
    });
  }

  Future<void> _showGenres(MovieListViewModel vm) async {
    final draft = {...?vm.selectedGenreIds};
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '장르 선택',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheetState(draft.clear),
                        child: const Text('전체'),
                      ),
                    ],
                  ),
                  const Text('여러 장르를 선택할 수 있어요.'),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final genre in vm.genres)
                            FilterChip(
                              key: ValueKey('genre-${genre.id}'),
                              label: Text(genre.name),
                              selected: draft.contains(genre.id),
                              onSelected: (selected) => setSheetState(() {
                                if (selected) {
                                  draft.add(genre.id);
                                } else {
                                  draft.remove(genre.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext, draft.toList()..sort()),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted && result != null) await vm.selectGenres(result);
  }

  @override
  void dispose() {
    _vm?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Consumer<MovieListViewModel>(
      builder: (context, vm, child) {
        final names = vm.genres
            .where((g) => vm.selectedGenreIds?.contains(g.id) ?? false)
            .map((g) => g.name)
            .join(' · ');
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '영화',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('movieOptionsButton'),
                    tooltip: '장르 선택',
                    onPressed: vm.busy || vm.genres.isEmpty
                        ? null
                        : () => _showGenres(vm),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: Text(names.isEmpty ? '전체' : names)),
                  Text('총 ${vm.movies.length}개'),
                ],
              ),
            ),
            if (vm.busy && vm.movies.isNotEmpty)
              const LinearProgressIndicator(),
            Expanded(
              child: vm.busy && vm.movies.isEmpty
                  ? const MovieListLoading()
                  : vm.status == MovieLoadStatus.error
                  ? MovieListError(onRetry: () => vm.load())
                  : RefreshIndicator(
                      notificationPredicate: (notification) =>
                          !vm.busy && notification.depth == 0,
                      onRefresh: () => vm.load(),
                      child: vm.movies.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) => ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: constraints.maxHeight,
                                    child: const MovieListEmpty(),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              key: const Key('movieList'),
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                14,
                                24,
                                24,
                              ),
                              itemCount: vm.movies.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final movie = vm.movies[index].toMovie(
                                  vm.genres,
                                );
                                return MovieCard(
                                  movie: movie,
                                  onTap: () => context.push(
                                    '/movies/${movie.id}',
                                    extra: movie,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}
