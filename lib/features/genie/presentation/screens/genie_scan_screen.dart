import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../data/genie_scan_data.dart';

/// Genie's ingredient/recipe scanner — there is no camera or ML plugin in
/// this project (see `pubspec.yaml`), so this fakes the scan → result flow
/// with a short delay and a fabricated but plausible detection, mirroring
/// `GenieScanScreen` from `screens-genie.jsx`.
class GenieScanScreen extends StatefulWidget {
  const GenieScanScreen({super.key});

  @override
  State<GenieScanScreen> createState() => _GenieScanScreenState();
}

class _GenieScanScreenState extends State<GenieScanScreen> {
  bool _scanning = false;
  bool _scanned = false;

  void _runScan() {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _scanned = false;
    });
    ToastService.instance.show('📸 Scanning...');
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanned = true;
      });
      ToastService.instance.show(
        '🧞 Genie detected ${GenieScanData.detectedIngredients.length} '
        'ingredients!',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2A00), Color(0xFF2A4A00), Color(0xFF1A3300)],
            stops: [0, 0.4, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: flow.goBack,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Text(
                      'Smart Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.4,
                      child: _scanning
                          ? const Pulse(
                              amount: 0.06,
                              child: Text(
                                '🥬🍅🍗',
                                style: TextStyle(fontSize: 80),
                              ),
                            )
                          : const Text(
                              '🥬🍅🍗',
                              style: TextStyle(fontSize: 80),
                            ),
                    ),
                    _corner(top: 40, left: 40, tl: true),
                    _corner(top: 40, right: 40, tr: true),
                    _corner(bottom: 40, left: 40, bl: true),
                    _corner(bottom: 40, right: 40, br: true),
                    if (_scanned)
                      Positioned(
                        bottom: 80,
                        left: 20,
                        right: 20,
                        child: ZoomIn(child: _buildDetectionCard()),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      'Find Recipes',
                      filled: true,
                      onTap: () => flow.setScreen(AppScreen.swipeDeck),
                    ),
                    _actionButton(
                      'Import Recipe',
                      onTap: () => ToastService.instance.show(
                        '🔍 Searching recipes from scan...',
                      ),
                    ),
                    _actionButton(
                      'Identify Dish',
                      onTap: () => ToastService.instance.show(
                        '🔍 Genie is identifying the dish... '
                        '${GenieScanData.identifiedDish} detected!',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => ToastService.instance.show(
                        '🖼 Opening photo gallery...',
                      ),
                      child: const Text('🖼', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: _runScan,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: _scanning
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: () => flow.setScreen(AppScreen.genie),
                      child: const Text(
                        '⌨️ Type',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
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

  Widget _buildDetectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.amber, size: 16),
              const SizedBox(width: 8),
              Text(
                '🧞 ${GenieScanData.detectedIngredients.length} found',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final ing in GenieScanData.detectedIngredients)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$ing ✓',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label, {
    bool filled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.coral : AppColors.glass,
          borderRadius: BorderRadius.circular(100),
          border: filled ? null : Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool tl = false,
    bool tr = false,
    bool bl = false,
    bool br = false,
  }) {
    final radius = const Radius.circular(8);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: tl ? radius : Radius.zero,
            topRight: tr ? radius : Radius.zero,
            bottomLeft: bl ? radius : Radius.zero,
            bottomRight: br ? radius : Radius.zero,
          ),
          border: Border(
            top: tl || tr
                ? const BorderSide(color: AppColors.cyan, width: 3)
                : BorderSide.none,
            left: tl || bl
                ? const BorderSide(color: AppColors.cyan, width: 3)
                : BorderSide.none,
            bottom: bl || br
                ? const BorderSide(color: AppColors.cyan, width: 3)
                : BorderSide.none,
            right: tr || br
                ? const BorderSide(color: AppColors.cyan, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
