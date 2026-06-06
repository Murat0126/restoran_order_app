import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../order_session_provider.dart';

/// Правая колонка корзины (Stitch `pos_2.3_2`, w-96).
class OrderCartPanel extends ConsumerWidget {
  const OrderCartPanel({
    super.key,
    required this.tableId,
    this.fixedWidth = true,
  });

  final String tableId;
  final bool fixedWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(orderSessionProvider(tableId)).valueOrNull;
    if (session == null) return const SizedBox.shrink();

    final s = context.appTheme;
    final cartWidth = s.layout.cartPanelWidth;
    final l10n = context.l10n;
    final order = session.order;
    final drafts = session.draftItems();
    final kitchen = session.kitchenItems();
    final hasNew = drafts.isNotEmpty;

    return Container(
      width: fixedWidth ? cartWidth : null,
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLow,
        border: Border(left: BorderSide(color: s.palette.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                s.spacing.lg,
                s.spacing.lg,
                s.spacing.lg,
                s.spacing.sm,
              ),
              children: [
                Text(
                  l10n.waiterOrderCartCurrent,
                  style: s.typography.labelCaps.copyWith(
                    color: s.palette.onSurfaceVariant,
                    fontSize: s.components.microFontSize,
                    letterSpacing: s.components.categorySectionLetterSpacing,
                  ),
                ),
                SizedBox(height: s.spacing.lg),
                if (kitchen.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.check_circle_outlined,
                    label: l10n.waiterOrderCartSentKitchen,
                    muted: true,
                  ),
                  SizedBox(height: s.spacing.md),
                  for (final item in kitchen) ...[
                    _KitchenLine(item: item),
                    SizedBox(height: s.spacing.md),
                  ],
                  Divider(color: s.palette.outlineVariant),
                  SizedBox(height: s.spacing.lg),
                ],
                if (drafts.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.pending_outlined,
                    label: l10n.waiterOrderCartNewItems,
                    color: s.palette.primary,
                  ),
                  SizedBox(height: s.spacing.md),
                  for (final item in drafts) ...[
                    _DraftLine(
                      item: item,
                      editable: session.canEdit,
                      onDecrement: () => ref
                          .read(orderSessionProvider(tableId).notifier)
                          .changeDraftQty(item, -1),
                      onIncrement: () => ref
                          .read(orderSessionProvider(tableId).notifier)
                          .incrementDraft(item),
                      onRemove: () => ref
                          .read(orderSessionProvider(tableId).notifier)
                          .removeItem(item),
                    ),
                    SizedBox(height: s.spacing.lg),
                  ],
                ] else if (kitchen.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: s.spacing.xxl),
                    child: Text(
                      l10n.waiterOrderCartEmpty,
                      style: s.typography.bodyMedium.copyWith(
                        color: s.palette.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(s.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(color: s.palette.outlineVariant),
                SizedBox(height: s.spacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.waiterOrderSumLabel,
                      style: s.typography.headlineSmall.copyWith(
                        color: s.palette.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatPrice(context, order.total),
                      style: s.typography.headlineMedium.copyWith(
                        color: s.palette.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: s.spacing.lg),
                _SendToKitchenButton(
                  tableId: tableId,
                  enabled: hasNew && session.canEdit,
                ),
                SizedBox(height: s.spacing.sm),
                OutlinedButton(
                  onPressed: () => context.go('/waiter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: s.palette.primary,
                    side: BorderSide(color: s.palette.outlineVariant),
                    padding: EdgeInsets.symmetric(vertical: s.spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s.radii.lg),
                    ),
                    textStyle: s.typography.labelStrong,
                  ),
                  child: Text(l10n.waiterSaveAndExit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendToKitchenButton extends ConsumerStatefulWidget {
  const _SendToKitchenButton({
    required this.tableId,
    required this.enabled,
  });

  final String tableId;
  final bool enabled;

  @override
  ConsumerState<_SendToKitchenButton> createState() =>
      _SendToKitchenButtonState();
}

class _SendToKitchenButtonState extends ConsumerState<_SendToKitchenButton> {
  bool _sending = false;

  Future<void> _send() async {
    if (_sending || !widget.enabled) return;
    final l10n = context.l10n;
    setState(() => _sending = true);
    try {
      final count = await ref
          .read(orderSessionProvider(widget.tableId).notifier)
          .sendToKitchen();
      if (!mounted) return;
      if (count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.waiterSendToKitchenEmpty)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.waiterSendToKitchenSuccess(count))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.waiterSendToKitchenFailed)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _PrimaryCartButton(
      label: l10n.waiterSendToKitchen,
      icon: Icons.send_outlined,
      enabled: widget.enabled && !_sending,
      loading: _sending,
      onPressed: _send,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.muted = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool muted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final fg = color ??
        (muted
            ? s.palette.onSurfaceVariant
            : s.palette.primary);
    return Row(
      children: [
        Icon(
          icon,
          size: s.components.iconSm,
          color: fg.withValues(alpha: muted ? 0.6 : 1),
        ),
        SizedBox(width: s.spacing.sm),
        Text(
          label.toUpperCase(),
          style: s.typography.labelStrong.copyWith(
            color: fg,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _KitchenLine extends StatelessWidget {
  const _KitchenLine({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Opacity(
      opacity: 0.7,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.dishName, style: s.typography.labelStrong),
                Text(
                  '${item.qty} × ${formatPrice(context, item.priceAtMoment)}',
                  style: s.typography.labelCaps.copyWith(
                    color: s.palette.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrice(context, item.lineTotal),
            style: s.typography.labelStrong,
          ),
        ],
      ),
    );
  }
}

class _DraftLine extends StatelessWidget {
  const _DraftLine({
    required this.item,
    required this.editable,
    this.onDecrement,
    this.onIncrement,
    this.onRemove,
  });

  final OrderItem item;
  final bool editable;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Container(
      padding: EdgeInsets.all(s.spacing.sm),
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        border: Border.all(
          color: s.palette.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: s.shadows.level1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.dishName, style: s.typography.labelStrong),
                Text(
                  formatPrice(context, item.priceAtMoment),
                  style: s.typography.labelStrong.copyWith(
                    color: s.palette.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: s.palette.surfaceContainer,
              borderRadius: BorderRadius.circular(s.radii.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: editable ? onDecrement : null,
                ),
                SizedBox(
                  width: s.spacing.xl,
                  child: Text(
                    '${item.qty}',
                    textAlign: TextAlign.center,
                    style: s.typography.labelStrong.copyWith(
                      fontSize: s.typography.bodySmall.fontSize,
                    ),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: editable ? onIncrement : null,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: s.palette.error,
              size: s.components.iconMd,
            ),
            onPressed: editable ? onRemove : null,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final touch = context.appTheme.spacing.xl;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: touch,
        height: touch,
        child: Icon(icon, size: context.appComponents.iconSm),
      ),
    );
  }
}

class _PrimaryCartButton extends StatelessWidget {
  const _PrimaryCartButton({
    required this.label,
    required this.icon,
    this.enabled = true,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final fg = s.palette.onPrimary;
    return Material(
      color: s.palette.primaryContainer,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: enabled && !loading ? onPressed : null,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: s.spacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: s.components.iconMd,
                    height: s.components.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                else
                  Icon(icon, size: s.components.iconMd, color: fg),
                SizedBox(width: s.spacing.sm),
                Text(
                  label,
                  style: s.typography.labelStrong.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
