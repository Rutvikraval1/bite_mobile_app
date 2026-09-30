import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../data/mock_social_data.dart';

/// Result of a completed quick-rate flow.
class QuickRateResult {
  const QuickRateResult({
    required this.rating,
    required this.comment,
    required this.photo,
  });

  final int rating; // 1..3
  final String comment;
  final bool photo;
}

/// Centered rating modal — ports `QuickRateModal`. Used by
/// [NotificationCenterScreen]'s smart "Rate Now" / "Rate Visit" notifications.
class QuickRateSheet extends StatefulWidget {
  const QuickRateSheet({
    super.key,
    required this.target,
    required this.onClose,
    required this.onShared,
  });

  final RateTarget target;
  final VoidCallback onClose;
  final ValueChanged<QuickRateResult> onShared;

  @override
  State<QuickRateSheet> createState() => _QuickRateSheetState();
}

class _QuickRateSheetState extends State<QuickRateSheet> {
  static const _peppers = [
    (level: 1, label: 'Good', color: Color(0xFF4CAF50), emoji: '🫑'),
    (level: 2, label: 'Great', color: Color(0xFFFF9800), emoji: '🍊'),
    (level: 3, label: 'Fire', color: Color(0xFFD32F2F), emoji: '🌶'),
  ];

  int? _rating;
  final TextEditingController _comment = TextEditingController();
  bool _photo = false;
  bool _shared = false;
  Timer? _shareTimer;

  int get _earnedPts => (_rating != null ? 5 : 0) + (_comment.text.isNotEmpty ? 3 : 0) + (_photo ? 5 : 0);

  @override
  void dispose() {
    _shareTimer?.cancel();
    _comment.dispose();
    super.dispose();
  }

  void _share() {
    final rating = _rating;
    if (rating == null) return;
    setState(() => _shared = true);
    _shareTimer?.cancel();
    _shareTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      widget.onShared(QuickRateResult(rating: rating, comment: _comment.text, photo: _photo));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlace = widget.target.isPlace;
    return GestureDetector(
      onTap: _shared ? null : widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () {},
          child: PopIn(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 64, offset: const Offset(0, 24)),
                ],
              ),
              child: _shared ? _buildShared() : _buildForm(isPlace),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShared() {
    final rating = _rating;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('Shared to Feed!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('+$_earnedPts points earned', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          if (rating != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_peppers[rating - 1].emoji} ${_peppers[rating - 1].label}',
              style: TextStyle(color: _peppers[rating - 1].color, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(bool isPlace) {
    final rating = _rating;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [
                    widget.target.color.withValues(alpha: 0.27),
                    widget.target.color.withValues(alpha: 0.07),
                  ]),
                ),
                alignment: Alignment.center,
                child: Text(widget.target.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.target.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(isPlace ? 'How was your visit?' : 'How was it?',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPlace ? 'HOW WAS IT?' : 'RATE THIS RECIPE',
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final p in _peppers)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: p.level > 1 ? 10 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _rating = p.level),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: rating == p.level
                                  ? p.color.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: rating == p.level ? p.color : Colors.white.withValues(alpha: 0.06),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Opacity(
                                  opacity: rating == p.level ? 1 : 0.5,
                                  child: Text(p.emoji, style: const TextStyle(fontSize: 32)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.label,
                                  style: TextStyle(
                                    color: rating == p.level ? p.color : AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (rating != null)
          SlideUp(
            duration: const Duration(milliseconds: 250),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _comment,
                    onTap: () {
                      if (_comment.text.isEmpty) {
                        setState(() => _comment.text = isPlace
                            ? 'Incredible atmosphere and the food was next level 🍽✨'
                            : "Perfectly seasoned, crispy outside, juicy inside — chef's kiss! 🤌🔥");
                      }
                    },
                    onChanged: (_) => setState(() {}),
                    maxLength: 150,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isPlace ? 'What was the highlight?' : 'What did you love about it?',
                      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                      counterStyle: const TextStyle(color: AppColors.muted, fontSize: 10),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _comment.text.isNotEmpty
                              ? AppColors.coral.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _photo = !_photo),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _photo ? AppColors.cyan.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _photo ? AppColors.cyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 16, color: _photo ? AppColors.cyan : AppColors.muted),
                          const SizedBox(width: 8),
                          Text(
                            _photo ? '📸 Photo added!' : 'Add a photo (+5 pts)',
                            style: TextStyle(
                                color: _photo ? AppColors.cyan : AppColors.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                          if (_photo) ...[
                            const Spacer(),
                            const Icon(Icons.check_rounded, size: 14, color: AppColors.cyan),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              if (rating != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '+$_earnedPts pts — Rate${_comment.text.isNotEmpty ? " + Review" : ""}${_photo ? " + Photo" : ""}',
                      style: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              GestureDetector(
                onTap: rating != null ? _share : null,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: rating != null
                        ? const LinearGradient(colors: [AppColors.coral, AppColors.amber])
                        : null,
                    color: rating != null ? null : Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Text(
                    rating != null ? 'Rate & Share to Feed 🌶' : 'Select a rating above',
                    style: TextStyle(
                      color: rating != null ? Colors.white : AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Skip for now', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
