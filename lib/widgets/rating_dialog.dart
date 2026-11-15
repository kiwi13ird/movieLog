import 'package:flutter/material.dart';

import '../data/models/api_failure.dart';
import '../data/models/rating_request.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
    super.key,
  });
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int, String?) onSubmit;
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _comment = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _score < 1) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        validateServerScore(_score.toDouble()),
        normalizedComment(_comment.text),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiFailure.from(error).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.initialScore == 0 ? '평점을 남겨주세요' : '평점 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MovieRatingInput(
              rating: _score.toDouble(),
              enabled: !_saving,
              onRatingUpdate: (v) =>
                  setState(() => _score = validateServerScore(v)),
            ),
            const SizedBox(height: 8),
            Text(_score == 0 ? '별점을 선택해 주세요.' : '$_score / 5.0'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('ratingCommentField'),
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              enabled: !_saving,
              decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _saving ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          key: const Key('ratingConfirmButton'),
          label: '확인',
          isLoading: _saving,
          onPressed: _score > 0 && !_saving ? _submit : null,
        ),
      ],
    ),
  );
}

class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({required this.onConfirm, super.key});
  final Future<void> Function() onConfirm;
  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _deleting = false;
  String? _error;
  Future<void> _confirm() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = ApiFailure.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('삭제한 평점은 복구할 수 없습니다.'),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          key: const Key('deleteConfirmButton'),
          label: '삭제',
          isLoading: _deleting,
          onPressed: _deleting ? null : _confirm,
        ),
      ],
    ),
  );
}
