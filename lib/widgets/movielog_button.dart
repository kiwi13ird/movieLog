import 'package:flutter/material.dart';

class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 44,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD5D2DC),
        disabledForegroundColor: const Color(0xFF777183),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? Semantics(
              label: '$label 진행 중',
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
