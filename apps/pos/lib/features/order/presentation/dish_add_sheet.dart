import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_quantity_stepper.dart';
import 'dish_sheet_modifiers.dart';

/// Режим панели блюда (Stitch `pos_2.4_2`).
enum DishSheetMode {
  /// Добавление в заказ столика.
  addToOrder,

  /// Просмотр из раздела «Меню».
  browse,
}

/// Модальное окно добавления блюда (центр экрана, max-width 840).
Future<void> showDishSheet(
  BuildContext context, {
  required Dish dish,
  required DishSheetMode mode,
  Future<void> Function({required int qty, String? note, int courseNo})? onAdd,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) {
      final s = ctx.appTheme;
      final screen = MediaQuery.sizeOf(ctx);
      final dialogW = math.min(840.0, screen.width - s.spacing.lg * 2);
      final dialogH = screen.height * 0.9;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(s.spacing.lg),
        child: SizedBox(
          width: dialogW,
          height: dialogH,
          child: _DishSheetDialog(
            dialogWidth: dialogW,
            dish: dish,
            mode: mode,
            onAdd: onAdd,
          ),
        ),
      );
    },
  );
}

class _DishSheetDialog extends StatefulWidget {
  const _DishSheetDialog({
    required this.dialogWidth,
    required this.dish,
    required this.mode,
    this.onAdd,
  });

  final double dialogWidth;
  final Dish dish;
  final DishSheetMode mode;
  final Future<void> Function({
    required int qty,
    String? note,
    int courseNo,
  })? onAdd;

  @override
  State<_DishSheetDialog> createState() => _DishSheetDialogState();
}

class _DishSheetDialogState extends State<_DishSheetDialog> {
  int _qty = 1;
  bool _course2 = false;
  bool _submitting = false;
  final _noteCtrl = TextEditingController();
  String? _selectedRadioId;
  final _checkedIds = <String>{};

  late final List<DishSheetModifierGroup> _modifierGroups;

  @override
  void initState() {
    super.initState();
    _modifierGroups = modifierGroupsForDish(widget.dish.id);
    for (final g in _modifierGroups) {
      if (g.singleSelect && g.options.isNotEmpty) {
        _selectedRadioId = g.options.length > 1
            ? g.options[1].id
            : g.options.first.id;
        break;
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _modifiersTotal {
    var total = 0.0;
    for (final g in _modifierGroups) {
      for (final o in g.options) {
        final selected = g.singleSelect
            ? _selectedRadioId == o.id
            : _checkedIds.contains(o.id);
        if (selected) total += o.priceDelta;
      }
    }
    return total;
  }

  double get _lineTotal => (widget.dish.effectivePrice + _modifiersTotal) * _qty;

  String? _buildNote() {
    final parts = <String>[];
    for (final g in _modifierGroups) {
      for (final o in g.options) {
        final selected = g.singleSelect
            ? _selectedRadioId == o.id
            : _checkedIds.contains(o.id);
        if (selected) parts.add(o.label);
      }
    }
    final userNote = _noteCtrl.text.trim();
    if (userNote.isNotEmpty) parts.add(userNote);
    if (parts.isEmpty) return null;
    return parts.join('; ');
  }

  Future<void> _submit() async {
    if (widget.mode != DishSheetMode.addToOrder || widget.onAdd == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onAdd!(
        qty: _qty,
        note: _buildNote(),
        courseNo: _course2 ? 2 : 1,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final dish = widget.dish;
    final canAdd = widget.mode == DishSheetMode.addToOrder;

    final wide = widget.dialogWidth >= 560;

    final form = _DishFormBody(
      dish: dish,
      canAdd: canAdd,
      course2: _course2,
      noteCtrl: _noteCtrl,
      modifierGroups: _modifierGroups,
      selectedRadioId: _selectedRadioId,
      checkedIds: _checkedIds,
      onCourse2Changed: canAdd ? (v) => setState(() => _course2 = v) : null,
      onRadioSelected:
          canAdd ? (id) => setState(() => _selectedRadioId = id) : null,
      onCheckboxToggled: canAdd
          ? (id, checked) => setState(() {
                if (checked) {
                  _checkedIds.add(id);
                } else {
                  _checkedIds.remove(id);
                }
              })
          : null,
    );

    final body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ColoredBox(
                  color: s.palette.surfaceContainerLow,
                  child: _DishImage(dish: dish),
                ),
              ),
              Expanded(
                flex: 7,
                child: SingleChildScrollView(child: form),
              ),
            ],
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: s.components.dishSheetImageHeightNarrow,
                  child: _DishImage(dish: dish),
                ),
                form,
              ],
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s.radii.lg),
        boxShadow: s.shadows.level2,
      ),
      child: Material(
        color: s.palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(dish: dish),
            Expanded(child: body),
            Divider(
              height: s.components.dividerThickness,
              thickness: s.components.dividerThickness,
              color: s.palette.outlineVariant,
            ),
            _DishFooter(
              canAdd: canAdd,
              submitting: _submitting,
              qty: _qty,
              lineTotalLabel: l10n.waiterDishAddConfirm(
                formatPrice(context, _lineTotal),
              ),
              cancelLabel:
                  canAdd ? l10n.waiterDishAddCancel : l10n.waiterDishClose,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
              onQtyChanged: (v) => setState(() => _qty = v),
              wide: wide,
            ),
          ],
        ),
      ),
    );
  }
}

class _DishFooter extends StatelessWidget {
  const _DishFooter({
    required this.canAdd,
    required this.submitting,
    required this.qty,
    required this.lineTotalLabel,
    required this.cancelLabel,
    required this.onCancel,
    required this.onSubmit,
    required this.onQtyChanged,
    required this.wide,
  });

  final bool canAdd;
  final bool submitting;
  final int qty;
  final String lineTotalLabel;
  final String cancelLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final ValueChanged<int> onQtyChanged;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;

    if (!canAdd) {
      return Padding(
        padding: EdgeInsets.all(s.spacing.lg),
        child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: s.palette.onSurfaceVariant,
            side: BorderSide(color: s.palette.outlineVariant),
            padding: EdgeInsets.symmetric(vertical: s.spacing.md),
            textStyle: s.typography.labelStrong,
          ),
          child: Text(cancelLabel),
        ),
      );
    }

    final stepper = AppQuantityStepper(
      value: qty,
      min: 1,
      enabled: !submitting,
      size: AppQuantityStepperSize.large,
      onDecrement: () => onQtyChanged((qty - 1).clamp(1, 99)),
      onIncrement: () => onQtyChanged((qty + 1).clamp(1, 99)),
    );

    return Padding(
      padding: EdgeInsets.all(s.spacing.lg),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                stepper,
                const Spacer(),
                OutlinedButton(
                  onPressed: submitting ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: s.palette.onSurfaceVariant,
                    side: BorderSide(color: s.palette.outlineVariant),
                    minimumSize: Size(0, s.components.buttonHeightMd),
                    padding: EdgeInsets.symmetric(
                      horizontal: s.spacing.xl,
                      vertical: s.spacing.md,
                    ),
                    textStyle: s.typography.labelStrong,
                  ),
                  child: Text(cancelLabel),
                ),
                SizedBox(width: s.spacing.md),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: submitting ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: s.palette.primary,
                      foregroundColor: s.palette.onPrimary,
                      minimumSize: Size(0, s.components.buttonHeightMd),
                      padding: EdgeInsets.symmetric(
                        horizontal: s.spacing.lg,
                        vertical: s.spacing.md,
                      ),
                    ),
                    icon: submitting
                        ? SizedBox(
                            width: s.components.iconMd,
                            height: s.components.iconMd,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: s.palette.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.shopping_cart_outlined,
                            size: s.components.iconMd,
                          ),
                    label: Text(
                      lineTotalLabel,
                      style: s.typography.labelStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: stepper),
                SizedBox(height: s.spacing.lg),
                OutlinedButton(
                  onPressed: submitting ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: s.palette.onSurfaceVariant,
                    side: BorderSide(color: s.palette.outlineVariant),
                    padding: EdgeInsets.symmetric(vertical: s.spacing.md),
                    textStyle: s.typography.labelStrong,
                  ),
                  child: Text(cancelLabel),
                ),
                SizedBox(height: s.spacing.sm),
                FilledButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: s.palette.primary,
                    foregroundColor: s.palette.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: s.spacing.md),
                  ),
                  icon: submitting
                      ? SizedBox(
                          width: s.components.iconMd,
                          height: s.components.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: s.palette.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.shopping_cart_outlined,
                          size: s.components.iconMd,
                        ),
                  label: Text(
                    lineTotalLabel,
                    style: s.typography.labelStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DishFormBody extends StatelessWidget {
  const _DishFormBody({
    required this.dish,
    required this.canAdd,
    required this.course2,
    required this.noteCtrl,
    required this.modifierGroups,
    required this.selectedRadioId,
    required this.checkedIds,
    this.onCourse2Changed,
    this.onRadioSelected,
    this.onCheckboxToggled,
  });

  final Dish dish;
  final bool canAdd;
  final bool course2;
  final TextEditingController noteCtrl;
  final List<DishSheetModifierGroup> modifierGroups;
  final String? selectedRadioId;
  final Set<String> checkedIds;
  final ValueChanged<bool>? onCourse2Changed;
  final ValueChanged<String>? onRadioSelected;
  final void Function(String id, bool checked)? onCheckboxToggled;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.all(s.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canAdd)
            for (final group in modifierGroups) ...[
              _ModifierGroupSection(
                title: group.titleKey == 'doneness'
                    ? l10n.waiterDishModifierDoneness
                    : l10n.waiterDishModifierOptions,
                group: group,
                selectedRadioId: selectedRadioId,
                checkedIds: checkedIds,
                onRadioSelected: onRadioSelected,
                onCheckboxToggled: onCheckboxToggled,
              ),
              SizedBox(height: s.spacing.xl),
            ],
          if (canAdd) ...[
            _SectionTitle(l10n.waiterDishCourseLabel),
            SizedBox(height: s.spacing.md),
            _CourseCard(
              course2: course2,
              onChanged: onCourse2Changed,
            ),
            SizedBox(height: s.spacing.xl),
            _SectionTitle(l10n.waiterDishCommentLabel),
            SizedBox(height: s.spacing.md),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: s.typography.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.waiterDishCommentHint,
                filled: true,
                fillColor: s.palette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s.radii.lg),
                  borderSide: BorderSide(color: s.palette.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s.radii.lg),
                  borderSide: BorderSide(color: s.palette.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(s.radii.lg),
                  borderSide: BorderSide(color: s.palette.primary, width: 1),
                ),
              ),
            ),
          ] else
            Text(
              dish.description.isNotEmpty
                  ? dish.description
                  : l10n.waiterDishBrowseFallback,
              style: s.typography.bodyMedium.copyWith(
                color: s.palette.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Text(
      text.toUpperCase(),
      style: s.typography.labelCaps.copyWith(
        color: s.palette.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ModifierGroupSection extends StatelessWidget {
  const _ModifierGroupSection({
    required this.title,
    required this.group,
    required this.selectedRadioId,
    required this.checkedIds,
    this.onRadioSelected,
    this.onCheckboxToggled,
  });

  final String title;
  final DishSheetModifierGroup group;
  final String? selectedRadioId;
  final Set<String> checkedIds;
  final ValueChanged<String>? onRadioSelected;
  final void Function(String id, bool checked)? onCheckboxToggled;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title),
        SizedBox(height: s.spacing.md),
        for (final option in group.options)
          Padding(
            padding: EdgeInsets.only(bottom: s.spacing.sm),
            child: group.singleSelect
                ? _RadioModifierTile(
                    label: option.label,
                    selected: selectedRadioId == option.id,
                    onTap: onRadioSelected == null
                        ? null
                        : () => onRadioSelected!(option.id),
                  )
                : _CheckboxModifierTile(
                    label: option.label,
                    priceDelta: option.priceDelta,
                    checked: checkedIds.contains(option.id),
                    onChanged: onCheckboxToggled == null
                        ? null
                        : (v) => onCheckboxToggled!(option.id, v ?? false),
                  ),
          ),
      ],
    );
  }
}

class _RadioModifierTile extends StatelessWidget {
  const _RadioModifierTile({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Container(
          padding: EdgeInsets.all(s.spacing.md),
          decoration: BoxDecoration(
            color: selected
                ? s.palette.secondaryContainer.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(s.radii.lg),
            border: Border.all(
              color: selected
                  ? s.palette.primary
                  : s.palette.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: s.typography.bodyMedium.copyWith(
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: s.palette.primary,
                size: s.components.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxModifierTile extends StatelessWidget {
  const _CheckboxModifierTile({
    required this.label,
    required this.priceDelta,
    required this.checked,
    this.onChanged,
  });

  final String label;
  final double priceDelta;
  final bool checked;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Material(
      color: s.palette.surfaceContainerLow,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(s.spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: s.typography.bodyMedium),
              ),
              if (priceDelta > 0) ...[
                Text(
                  '+${formatPrice(context, priceDelta)}',
                  style: s.typography.bodySmall.copyWith(
                    color: s.palette.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: s.spacing.sm),
              ],
              Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: s.palette.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course2,
    this.onChanged,
  });

  final bool course2;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!course2),
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Container(
          padding: EdgeInsets.all(s.spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s.radii.lg),
            border: Border.all(color: s.palette.outlineVariant),
          ),
          child: Row(
            children: [
              Checkbox(
                value: course2,
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged!(v ?? false),
                activeColor: s.palette.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              SizedBox(width: s.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.waiterDishCourseSecond,
                      style: s.typography.bodyMedium,
                    ),
                    Text(
                      l10n.waiterDishCourseDefault,
                      style: s.typography.bodySmall.copyWith(
                        color: s.palette.onSurfaceVariant,
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
}

class _Header extends StatelessWidget {
  const _Header({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: s.palette.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: s.spacing.lg,
          vertical: s.spacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: s.typography.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dish.description.isNotEmpty) ...[
                    SizedBox(height: s.spacing.xs),
                    Text(
                      dish.description,
                      style: s.typography.bodySmall.copyWith(
                        color: s.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: s.spacing.lg),
            Text(
              formatPrice(context, dish.effectivePrice),
              style: s.typography.headlineMedium.copyWith(
                color: s.palette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishImage extends StatelessWidget {
  const _DishImage({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;
    if (dish.images.isEmpty) {
      return ColoredBox(
        color: p.surfaceContainerHigh,
        child: Center(
          child: Icon(
            Icons.restaurant,
            size: s.components.iconEmpty,
            color: p.onSurfaceVariant,
          ),
        ),
      );
    }
    return Image.network(
      dish.images.first,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: p.surfaceContainerHigh,
        child: Center(
          child: Icon(Icons.broken_image, color: p.onSurfaceVariant),
        ),
      ),
    );
  }
}
