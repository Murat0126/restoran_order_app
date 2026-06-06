/// Демо-группы модификаторов для pixel-perfect Stitch 2.4.
///
/// Пока API не отдаёт модификаторы — показываем для блюд с известным id.
class DishSheetModifierOption {
  const DishSheetModifierOption({
    required this.id,
    required this.label,
    this.priceDelta = 0,
  });

  final String id;
  final String label;
  final double priceDelta;
}

class DishSheetModifierGroup {
  const DishSheetModifierGroup({
    required this.titleKey,
    required this.singleSelect,
    required this.options,
  });

  /// Ключ l10n (`waiterDishModifierDoneness` / `waiterDishModifierOptions`).
  final String titleKey;
  final bool singleSelect;
  final List<DishSheetModifierOption> options;
}

/// Группы модификаторов по id блюда (Stitch «Стейк Рибай»).
List<DishSheetModifierGroup> modifierGroupsForDish(String dishId) {
  if (dishId != 'd-5') return const [];

  return const [
    DishSheetModifierGroup(
      titleKey: 'doneness',
      singleSelect: true,
      options: [
        DishSheetModifierOption(id: 'rare', label: 'Rare (С кровью)'),
        DishSheetModifierOption(id: 'medium', label: 'Medium (Средняя)'),
        DishSheetModifierOption(id: 'well', label: 'Well Done (Полная)'),
      ],
    ),
    DishSheetModifierGroup(
      titleKey: 'options',
      singleSelect: false,
      options: [
        DishSheetModifierOption(id: 'no-onion', label: 'Без лука'),
        DishSheetModifierOption(
          id: 'extra-sauce',
          label: 'Дополнительный соус',
          priceDelta: 50,
        ),
      ],
    ),
  ];
}
