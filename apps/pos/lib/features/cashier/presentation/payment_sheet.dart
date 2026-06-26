import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_button.dart';
import '../cashier_orders_provider.dart';

/// Открывает модальный лист приёма оплаты по заказу (Stitch 3.3 / 3.4).
Future<void> showPaymentSheet(
  BuildContext context, {
  required Order order,
  required RestaurantTable? table,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(order: order, table: table),
  );
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.order, required this.table});

  final Order order;
  final RestaurantTable? table;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late PaymentMethod _method = PaymentMethod.cash;
  late final TextEditingController _amountCtrl;
  bool _busy = false;

  double get _balance => widget.order.balance;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: _balance.toStringAsFixed(_balance.truncateToDouble() == _balance ? 0 : 2),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _enteredAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.').trim()) ?? 0;

  Future<void> _confirm() async {
    if (_busy) return;
    final amount = _enteredAmount;
    if (amount <= 0) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cashierOrdersProvider.notifier).pay(
            widget.order.id,
            method: _method,
            amount: amount,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cashierPaySuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cashierPayError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final order = widget.order;
    final tableNo =
        widget.table != null ? formatTableNumber(widget.table!.number) : '—';

    final items = order.items
        .where((i) => i.status != OrderItemStatus.cancelled)
        .toList(growable: false);

    final amount = _enteredAmount;
    final change = _method == PaymentMethod.cash && amount > _balance
        ? amount - _balance
        : 0.0;
    final remaining = amount < _balance ? _balance - amount : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: s.palette.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(s.radii.xl),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _grabber(s),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  s.spacing.lg,
                  0,
                  s.spacing.lg,
                  s.spacing.sm,
                ),
                child: Text(
                  l10n.cashierTableTitle(tableNo),
                  style: s.typography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: s.spacing.lg),
                  children: [
                    Text(
                      l10n.cashierPayItemsTitle,
                      style: s.typography.labelCaps.copyWith(
                        color: s.palette.onSurfaceVariant,
                        fontSize: s.components.microFontSize,
                      ),
                    ),
                    SizedBox(height: s.spacing.sm),
                    for (final item in items)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: s.spacing.xs),
                        child: Row(
                          children: [
                            Text(
                              '${item.qty}×',
                              style: s.typography.labelStrong.copyWith(
                                color: s.palette.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: s.spacing.sm),
                            Expanded(
                              child: Text(
                                item.dishName,
                                style: s.typography.bodyMedium,
                              ),
                            ),
                            Text(
                              formatPrice(context, item.lineTotal),
                              style: s.typography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    Divider(height: s.spacing.lg, color: s.palette.outlineVariant),
                    _totalRow(s, l10n.cashierPaySubtotal,
                        formatPrice(context, order.subtotal)),
                    if (order.discountAmount > 0)
                      _totalRow(s, l10n.cashierPayDiscount,
                          '−${formatPrice(context, order.discountAmount)}'),
                    if (order.serviceAmount > 0)
                      _totalRow(s, l10n.cashierPayService,
                          formatPrice(context, order.serviceAmount)),
                    if (order.paidAmount > 0)
                      _totalRow(s, l10n.cashierPayPaid,
                          '−${formatPrice(context, order.paidAmount)}'),
                    _totalRow(
                      s,
                      l10n.cashierPayBalance,
                      formatPrice(context, _balance),
                      emphasize: true,
                    ),
                    SizedBox(height: s.spacing.lg),
                    Text(
                      l10n.cashierPayMethodLabel,
                      style: s.typography.labelCaps.copyWith(
                        color: s.palette.onSurfaceVariant,
                        fontSize: s.components.microFontSize,
                      ),
                    ),
                    SizedBox(height: s.spacing.sm),
                    _MethodSelector(
                      method: _method,
                      onChanged: (m) => setState(() => _method = m),
                    ),
                    SizedBox(height: s.spacing.lg),
                    Text(
                      l10n.cashierPayAmountLabel,
                      style: s.typography.labelCaps.copyWith(
                        color: s.palette.onSurfaceVariant,
                        fontSize: s.components.microFontSize,
                      ),
                    ),
                    SizedBox(height: s.spacing.sm),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: s.typography.headlineSmall,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: s.palette.surfaceContainer,
                        suffixText: 'с',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(s.radii.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (change > 0) ...[
                      SizedBox(height: s.spacing.sm),
                      Text(
                        l10n.cashierPayChange(formatPrice(context, change)),
                        style: s.typography.labelStrong.copyWith(
                          color: s.palette.primary,
                        ),
                      ),
                    ],
                    if (remaining > 0) ...[
                      SizedBox(height: s.spacing.sm),
                      Text(
                        l10n.cashierPayPartialRemaining(
                          formatPrice(context, remaining),
                        ),
                        style: s.typography.labelStrong.copyWith(
                          color: s.palette.error,
                        ),
                      ),
                    ],
                    SizedBox(height: s.spacing.lg),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  s.spacing.lg,
                  0,
                  s.spacing.lg,
                  s.spacing.lg,
                ),
                child: AppButton.fullWidth(
                  label: l10n.cashierPayConfirm,
                  icon: Icons.payments_outlined,
                  isLoading: _busy,
                  onPressed: amount > 0 ? _confirm : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabber(AppTheme s) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: s.spacing.sm),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: s.palette.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );

  Widget _totalRow(
    AppTheme s,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final labelStyle = emphasize
        ? s.typography.labelStrong
        : s.typography.bodyMedium.copyWith(color: s.palette.onSurfaceVariant);
    final valueStyle = emphasize
        ? s.typography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: s.palette.onSurface,
          )
        : s.typography.bodyMedium;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.spacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.method, required this.onChanged});

  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    final options = <(PaymentMethod, String, IconData)>[
      (PaymentMethod.cash, l10n.cashierPayMethodCash, Icons.payments_outlined),
      (PaymentMethod.card, l10n.cashierPayMethodCard, Icons.credit_card),
      (
        PaymentMethod.transfer,
        l10n.cashierPayMethodTransfer,
        Icons.account_balance_outlined
      ),
    ];

    return Row(
      children: [
        for (final (m, label, icon) in options) ...[
          Expanded(
            child: _MethodTile(
              label: label,
              icon: icon,
              selected: method == m,
              onTap: () => onChanged(m),
            ),
          ),
          if (m != options.last.$1) SizedBox(width: s.spacing.sm),
        ],
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final fg =
        selected ? s.palette.onPrimaryContainer : s.palette.onSurfaceVariant;
    return Material(
      color: selected
          ? s.palette.primaryContainer
          : s.palette.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: s.spacing.md),
          child: Column(
            children: [
              Icon(icon, size: s.components.iconMd, color: fg),
              SizedBox(height: s.spacing.xs),
              Text(
                label,
                style: s.typography.labelStrong.copyWith(color: fg),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
