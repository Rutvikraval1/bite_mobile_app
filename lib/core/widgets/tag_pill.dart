import 'package:flutter/material.dart';

/// A rounded tag pill. Ports the prototype's `TagPill`.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.emoji,
    this.color,
    this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final String? emoji;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? (selected ? const Color(0xFFFF6B6B) : Colors.white);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : const Color(0x1AFFFFFF),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : const Color(0xB3FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
