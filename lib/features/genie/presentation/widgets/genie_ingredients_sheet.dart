import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../data/genie_planner_data.dart';

/// Combined shopping list across every dish in the plan, grouped by dish,
/// with a checklist plus a one-tap "order the rest" flow.
///
/// The prototype opens a second nested bottom sheet per grocery service
/// (Instacart / Amazon Fresh / Walmart) listing the missing items before
/// checkout. There's no real grocery-delivery integration here, so ordering
/// is simulated in one step: tapping a service marks everything checked and
/// confirms via toast — the same end state, less modal-on-modal chrome.
class GenieIngredientsSheet extends StatelessWidget {
  const GenieIngredientsSheet({
    super.key,
    required this.dishes,
    required this.checked,
    required this.onToggle,
    required this.onClose,
    required this.onOrder,
    required this.onCookAnyway,
  });

  final List<GenieDish> dishes;
  final Map<String, bool> checked;
  final void Function(String key) onToggle;
  final VoidCallback onClose;
  final void Function(String service, int missingCount) onOrder;
  final VoidCallback onCookAnyway;

  int get _totalIngredients =>
      dishes.fold(0, (sum, d) => sum + d.ingredients.length);

  int get _checkedCount => checked.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final missing = _totalIngredients - _checkedCount;
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withValues(alpha: 0.55),
          onDismiss: onClose,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideUp(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.glassBorder),
                    left: BorderSide(color: AppColors.glassBorder),
                    right: BorderSide(color: AppColors.glassBorder),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 48,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🧾 All Ingredients ($_totalIngredients)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '$_checkedCount checked off · $missing '
                                      'remaining',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: onClose,
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          for (var di = 0; di < dishes.length; di++)
                            _DishIngredientGroup(
                              dish: dishes[di],
                              checked: checked,
                              onToggle: onToggle,
                              index: di,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: missing > 0
                          ? Column(
                              children: [
                                Text(
                                  '$missing missing ingredient'
                                  '${missing > 1 ? 's' : ''} across all dishes',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _orderButton(
                                        '🛒 Instacart ($missing)',
                                        const Color(0x2643A047),
                                        const Color(0xFF66BB6A),
                                        () => onOrder('Instacart', missing),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: _orderButton(
                                        '🟠 Amazon ($missing)',
                                        const Color(0x1AFF9900),
                                        const Color(0xFFFF9900),
                                        () => onOrder('Amazon Fresh', missing),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _orderButton(
                                      '🔵',
                                      const Color(0x1A0071CE),
                                      const Color(0xFF0071CE),
                                      () => onOrder('Walmart', missing),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: TextButton(
                                    onPressed: onCookAnyway,
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cook Anyway 🔥',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: onClose,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.saveGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: const Text(
                                  '✅ All Ingredients Ready — Let\'s Cook!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderButton(String label, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DishIngredientGroup extends StatelessWidget {
  const _DishIngredientGroup({
    required this.dish,
    required this.checked,
    required this.onToggle,
    required this.index,
  });

  final GenieDish dish;
  final Map<String, bool> checked;
  final void Function(String key) onToggle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final checkedCount = List.generate(
      dish.ingredients.length,
      (i) => i,
    ).where((i) => checked['${dish.id}-$i'] ?? false).length;
    return ZoomIn(
      duration: Duration(milliseconds: 220 + index * 60),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: dish.color, width: 3)),
              ),
              child: Row(
                children: [
                  Text(dish.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dish.name,
                      style: TextStyle(
                        color: dish.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: dish.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: dish.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      '$checkedCount/${dish.ingredients.length}',
                      style: TextStyle(
                        color: dish.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (var ii = 0; ii < dish.ingredients.length; ii++)
              _IngredientRow(
                label: dish.ingredients[ii],
                checkedValue: checked['${dish.id}-$ii'] ?? false,
                onTap: () => onToggle('${dish.id}-$ii'),
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.label,
    required this.checkedValue,
    required this.onTap,
  });

  final String label;
  final bool checkedValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: checkedValue
              ? const Color(0x0F4CAF50)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checkedValue
                ? const Color(0x264CAF50)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checkedValue ? AppColors.saveGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checkedValue
                      ? AppColors.saveGreen
                      : Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: checkedValue
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: checkedValue
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white,
                  fontSize: 13,
                  decoration: checkedValue
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
