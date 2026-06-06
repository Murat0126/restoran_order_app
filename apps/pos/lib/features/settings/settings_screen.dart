import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_base_url.dart';
import '../../core/api/api_client_provider.dart';
import '../../core/formatters/formatters.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/connection_indicator.dart';

/// Демо-экран Настроек для F3 (темизация) + F2 (локализация).
///
/// Назначение этого экрана сейчас:
///  • выбрать тему клиента (default / hushed_luxury);
///  • выбрать режим (Light / Dark / System);
///  • выбрать язык интерфейса (Русский / Кыргызча / системный);
///  • увидеть «живое» превью всех 9 типографических ролей,
///    основных M3-цветов, surface-уровней и базовых компонентов.
///
/// После F6 (базовые виджеты) превью заменится на витрину
/// собственных компонентов design-system.
///
/// Образцы данных (имена блюд, номера столов, цены) намеренно
/// оставлены в коде и НЕ переведены — это превью токенов, а не
/// продакшен-текст. На реальных экранах (Этап 1) такие данные
/// придут с сервера.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: s.palette.surface,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: s.palette.surfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: s.spacing.lg,
            vertical: s.spacing.md,
          ),
          children: [
            const _ServerCard(),
            SizedBox(height: s.spacing.lg),
            const _ThemePickerCard(),
            SizedBox(height: s.spacing.lg),
            const _ThemeModeCard(),
            SizedBox(height: s.spacing.lg),
            const _LanguageCard(),
            SizedBox(height: s.spacing.lg),
            _SectionHeader(l10n.settingsPreviewTypographySection),
            SizedBox(height: s.spacing.sm),
            const _TypographyPreview(),
            SizedBox(height: s.spacing.lg),
            _SectionHeader(l10n.settingsPreviewPaletteSection),
            SizedBox(height: s.spacing.sm),
            const _CoreColorsPreview(),
            SizedBox(height: s.spacing.lg),
            _SectionHeader(l10n.settingsPreviewSurfacesSection),
            SizedBox(height: s.spacing.sm),
            const _SurfaceLevelsPreview(),
            SizedBox(height: s.spacing.lg),
            _SectionHeader(l10n.settingsPreviewFormattersSection),
            SizedBox(height: s.spacing.sm),
            const _FormattersPreview(),
            SizedBox(height: s.spacing.lg),
            _SectionHeader(l10n.settingsPreviewWidgetsSection),
            SizedBox(height: s.spacing.sm),
            const _ComponentsPreview(),
            SizedBox(height: s.spacing.lg),
            const _StatesPreview(),
            SizedBox(height: s.spacing.xl),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Переключатели темы / режима / языка.
// ───────────────────────────────────────────────────────────────────────

class _ThemePickerCard extends ConsumerWidget {
  const _ThemePickerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final options = ref.watch(availableThemesProvider);
    final current = ref.watch(themeIdProvider);

    return _PanelCard(
      title: l10n.settingsThemeSectionTitle,
      subtitle: l10n.settingsThemeSectionSubtitle,
      child: RadioGroup<String>(
        groupValue: current,
        onChanged: (id) {
          if (id != null) {
            ref.read(themeIdProvider.notifier).set(id);
          }
        },
        child: Column(
          children: [
            for (final o in options)
              RadioListTile<String>(
                value: o.id,
                title: Text(o.displayName),
                subtitle: Text(
                  o.assetPath,
                  style: s.typography.bodySmall
                      .copyWith(color: s.palette.onSurfaceVariant),
                ),
                activeColor: s.palette.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final current = ref.watch(themeModeProvider);

    return _PanelCard(
      title: l10n.settingsModeSectionTitle,
      subtitle: l10n.settingsModeSectionSubtitle,
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
            value: ThemeMode.light,
            label: Text(l10n.settingsModeLight),
            icon: const Icon(Icons.light_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text(l10n.settingsModeDark),
            icon: const Icon(Icons.dark_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            label: Text(l10n.settingsModeSystem),
            icon: const Icon(Icons.settings_brightness_outlined),
          ),
        ],
        selected: <ThemeMode>{current},
        onSelectionChanged: (set) {
          ref.read(themeModeProvider.notifier).set(set.first);
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: s.palette.primaryContainer,
          selectedForegroundColor: s.palette.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ServerCard extends ConsumerStatefulWidget {
  const _ServerCard();

  @override
  ConsumerState<_ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends ConsumerState<_ServerCard> {
  final _urlCtrl = TextEditingController();
  bool _testing = false;
  String? _testMessage;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = ref.read(apiBaseUrlProvider);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    await ref.read(apiBaseUrlProvider.notifier).set(url);
    if (!mounted) return;
    setState(() {
      _testMessage = null;
      // Поле перерисуется через watch ниже.
    });
  }

  Future<void> _reset() async {
    await ref.read(apiBaseUrlProvider.notifier).reset();
    if (!mounted) return;
    _urlCtrl.text = ref.read(apiBaseUrlProvider);
    setState(() => _testMessage = null);
  }

  Future<void> _test() async {
    if (_testing) return;
    // Снимаем l10n до любых await — чтобы не цепляться к BuildContext
    // через async gap (use_build_context_synchronously).
    final l10n = context.l10n;
    // Сохраняем перед тестом — пользователь скорее всего хочет
    // проверить введённый URL, а не предыдущий.
    if (_urlCtrl.text.trim() != ref.read(apiBaseUrlProvider)) {
      await _save();
    }
    if (!mounted) return;
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    try {
      // Берём свежий клиент уже после save (а значит — с новым baseUrl).
      final client = ref.read(restaurantApiClientProvider);
      final ms = await client.health();
      if (!mounted) return;
      setState(() {
        _testOk = true;
        _testMessage = l10n.settingsServerTestOk(ms);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMessage = l10n.settingsServerTestFail(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMessage = l10n.settingsServerTestFail(e.toString());
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final currentUrl = ref.watch(apiBaseUrlProvider);
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settingsServerSectionTitle,
                        style: s.typography.headlineSmall),
                    SizedBox(height: s.spacing.xs),
                    Text(
                      l10n.settingsServerSectionSubtitle,
                      style: s.typography.bodySmall.copyWith(
                        color: s.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const ConnectionIndicator(compact: false),
            ],
          ),
          SizedBox(height: s.spacing.md),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: l10n.settingsServerBaseUrlLabel,
              hintText: l10n.settingsServerBaseUrlHint,
              prefixIcon: const Icon(Icons.link_outlined),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            enabled: !_testing,
          ),
          SizedBox(height: s.spacing.xs),
          Text(
            l10n.settingsServerCurrent(currentUrl),
            style: s.typography.bodySmall.copyWith(
              color: s.palette.onSurfaceVariant,
            ),
          ),
          SizedBox(height: s.spacing.sm),
          Wrap(
            spacing: s.spacing.sm,
            runSpacing: s.spacing.sm,
            children: [
              FilledButton.icon(
                onPressed: _testing ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.settingsServerSave),
              ),
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check_outlined),
                label: Text(_testing
                    ? l10n.settingsServerTesting
                    : l10n.settingsServerTestConnection),
              ),
              TextButton.icon(
                onPressed: _testing ? null : _reset,
                icon: const Icon(Icons.restart_alt_outlined),
                label: Text(l10n.settingsServerReset),
              ),
            ],
          ),
          if (_testMessage != null) ...[
            SizedBox(height: s.spacing.sm),
            Container(
              padding: EdgeInsets.all(s.spacing.sm),
              decoration: BoxDecoration(
                color: _testOk
                    ? s.palette.secondaryContainer
                    : s.palette.errorContainer,
                borderRadius: BorderRadius.circular(s.radii.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    _testOk
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: s.components.iconSm,
                    color: _testOk
                        ? s.palette.onSecondaryContainer
                        : s.palette.onErrorContainer,
                  ),
                  SizedBox(width: s.spacing.sm),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: s.typography.bodySmall.copyWith(
                        color: _testOk
                            ? s.palette.onSecondaryContainer
                            : s.palette.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final languages = ref.watch(supportedLanguagesProvider);
    final current = ref.watch(localeProvider);

    // 'system' — отдельное значение «следовать системе», остальные —
    // languageCode выбранной локали.
    final groupValue = current?.languageCode ?? 'system';

    return _PanelCard(
      title: l10n.settingsLanguageSectionTitle,
      subtitle: l10n.settingsLanguageSectionSubtitle,
      child: RadioGroup<String>(
        groupValue: groupValue,
        onChanged: (code) {
          if (code == null) return;
          final notifier = ref.read(localeProvider.notifier);
          if (code == 'system') {
            notifier.set(null);
          } else {
            notifier.set(Locale(code));
          }
        },
        child: Column(
          children: [
            for (final lang in languages)
              RadioListTile<String>(
                value: lang.locale.languageCode,
                title: Text(lang.displayName),
                activeColor: s.palette.primary,
              ),
            RadioListTile<String>(
              value: 'system',
              title: Text(l10n.settingsModeSystem),
              activeColor: s.palette.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Типография — 9 ролей. Метки HEADLINE LARGE и т.п. — технические
// маркеры для разработчика, поэтому не переводятся.
// ───────────────────────────────────────────────────────────────────────

class _TypographyPreview extends StatelessWidget {
  const _TypographyPreview();

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    Widget row(String label, TextStyle style, String sample) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: s.spacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 180,
              child: Text(
                label,
                style: s.typography.labelCaps.copyWith(
                  color: s.palette.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Text(sample, style: style)),
          ],
        ),
      );
    }

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('HEADLINE LARGE',         s.typography.headlineLarge,        'Заказ #1428'),
          row('HEADLINE LARGE MOBILE',  s.typography.headlineLargeMobile,  'Заказ #1428'),
          row('HEADLINE MEDIUM',        s.typography.headlineMedium,       'Цезарь с курицей'),
          row('HEADLINE SMALL',         s.typography.headlineSmall,        'Стол 5 · 4 гостя'),
          row('BODY LARGE',             s.typography.bodyLarge,            'Свежий салат с курицей и сыром пармезан'),
          row('BODY MEDIUM',            s.typography.bodyMedium,           'Свежий салат с курицей и сыром пармезан'),
          row('BODY SMALL',             s.typography.bodySmall,            'Без лука, пожалуйста'),
          row('LABEL STRONG',           s.typography.labelStrong,          'Добавить в заказ'),
          row('LABEL CAPS',             s.typography.labelCaps,            'ОЖИДАНИЕ'),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Палитра — основные роли.
// ───────────────────────────────────────────────────────────────────────

class _CoreColorsPreview extends StatelessWidget {
  const _CoreColorsPreview();

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;
    return _PanelCard(
      child: Wrap(
        spacing: context.appSpacing.sm,
        runSpacing: context.appSpacing.sm,
        children: [
          _Swatch('primary',            p.primary,            p.onPrimary),
          _Swatch('primaryContainer',   p.primaryContainer,   p.onPrimaryContainer),
          _Swatch('secondary',          p.secondary,          p.onSecondary),
          _Swatch('secondaryContainer', p.secondaryContainer, p.onSecondaryContainer),
          _Swatch('tertiary',           p.tertiary,           p.onTertiary),
          _Swatch('tertiaryContainer',  p.tertiaryContainer,  p.onTertiaryContainer),
          _Swatch('error',              p.error,              p.onError),
          _Swatch('errorContainer',     p.errorContainer,     p.onErrorContainer),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Container(
      width: 200,
      padding: EdgeInsets.all(s.spacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(s.radii.md),
        border: Border.all(color: s.palette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: s.typography.labelStrong.copyWith(color: fg)),
          SizedBox(height: s.spacing.xs),
          Text(
            '#${bg.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: s.typography.bodySmall.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Surface levels — для тонального слоения.
// ───────────────────────────────────────────────────────────────────────

class _SurfaceLevelsPreview extends StatelessWidget {
  const _SurfaceLevelsPreview();

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;
    final levels = <(String, Color)>[
      ('surface',                 p.surface),
      ('surfaceContainerLowest',  p.surfaceContainerLowest),
      ('surfaceContainerLow',     p.surfaceContainerLow),
      ('surfaceContainer',        p.surfaceContainer),
      ('surfaceContainerHigh',    p.surfaceContainerHigh),
      ('surfaceContainerHighest', p.surfaceContainerHighest),
      ('surfaceDim',              p.surfaceDim),
      ('surfaceBright',           p.surfaceBright),
    ];
    return _PanelCard(
      child: Wrap(
        spacing: context.appSpacing.sm,
        runSpacing: context.appSpacing.sm,
        children: [
          for (final (label, color) in levels)
            _Swatch(label, color, p.onSurface),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Компоненты — Card / Chip / Buttons / Input + тени.
// ───────────────────────────────────────────────────────────────────────

class _FormattersPreview extends StatelessWidget {
  const _FormattersPreview();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sample = formatPrice(context, 1240);
    final sampleDec = formatPrice(context, 350.5, forceDecimals: true);

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formatterRow(context, 'formatPrice', sample),
          _formatterRow(context, 'formatPrice (dec)', sampleDec),
          _formatterRow(context, 'formatDate', formatDate(context, now)),
          _formatterRow(context, 'formatTime', formatTime(context, now)),
          _formatterRow(
            context,
            'formatDateTime',
            formatDateTime(context, now),
          ),
          _formatterRow(
            context,
            'formatDuration',
            formatDuration(context, const Duration(hours: 1, minutes: 5)),
          ),
          _formatterRow(
            context,
            'formatOrderNumber',
            formatOrderNumber(1428),
          ),
        ],
      ),
    );
  }

  Widget _formatterRow(BuildContext context, String label, String value) {
    final s = context.appTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: s.typography.labelCaps.copyWith(
                color: s.palette.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: s.typography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ComponentsPreview extends StatelessWidget {
  const _ComponentsPreview();

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final p = s.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelCard(
          title: l10n.settingsComponentsButtons,
          child: Wrap(
            spacing: s.spacing.sm,
            runSpacing: s.spacing.sm,
            children: [
              AppButton(
                label: l10n.buttonConfirm,
                onPressed: () {},
              ),
              AppButton(
                label: l10n.buttonCancel,
                variant: AppButtonVariant.outlined,
                onPressed: () {},
              ),
              AppButton(
                label: l10n.buttonDetails,
                variant: AppButtonVariant.text,
                onPressed: () {},
              ),
              AppButton(
                label: l10n.buttonPrintReceipt,
                icon: Icons.print_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              const AppButton(
                label: '…',
                isLoading: true,
                onPressed: null,
              ),
            ],
          ),
        ),
        SizedBox(height: s.spacing.md),
        _PanelCard(
          title: l10n.settingsComponentsChips,
          child: Wrap(
            spacing: s.spacing.sm,
            runSpacing: s.spacing.sm,
            children: const [
              AppChip(label: 'ВЕГ'),
              AppChip(label: 'ОСТРОЕ', variant: AppChipVariant.warning),
              AppChip(label: 'ГОТОВО', variant: AppChipVariant.success),
              AppChip(label: 'Горячие', selected: true),
            ],
          ),
        ),
        SizedBox(height: s.spacing.md),
        _PanelCard(
          title: l10n.settingsComponentsInput,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.formGuestName,
                  hintText: l10n.formGuestNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: s.spacing.sm),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.formPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_outlined),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: s.spacing.md),
        _PanelCard(
          title: l10n.settingsComponentsCard,
          child: AppCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    borderRadius: BorderRadius.circular(s.radii.md),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: p.onPrimaryContainer,
                  ),
                ),
                SizedBox(width: s.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Цезарь с курицей',
                        style: s.typography.headlineSmall,
                      ),
                      SizedBox(height: s.spacing.xs),
                      Text(
                        'Свежий салат с курицей и сыром пармезан',
                        style: s.typography.bodyMedium.copyWith(
                          color: p.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatPrice(context, 350),
                  style: s.typography.headlineSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatesPreview extends StatelessWidget {
  const _StatesPreview();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          level: AppCardLevel.flat,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 200,
            child: AppEmptyState(
              title: l10n.emptyStateNoOrdersTitle,
              subtitle: l10n.emptyStateNoOrdersSubtitle,
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ),
        SizedBox(height: s.spacing.md),
        AppCard(
          level: AppCardLevel.flat,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 220,
            child: AppErrorState(
              title: l10n.errorStateGenericTitle,
              subtitle: l10n.errorStateGenericSubtitle,
              retryLabel: l10n.actionRetry,
              onRetry: () {},
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Низкоуровневые helpers — заголовок секции и панель-карточка.
// ───────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.spacing.sm),
      child: Text(
        text,
        style: s.typography.labelCaps.copyWith(
          color: s.palette.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({this.title, this.subtitle, required this.child});

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Container(
      padding: EdgeInsets.all(s.spacing.lg),
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        boxShadow: s.shadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: s.typography.headlineSmall),
            if (subtitle != null) ...[
              SizedBox(height: s.spacing.xs),
              Text(
                subtitle!,
                style: s.typography.bodySmall
                    .copyWith(color: s.palette.onSurfaceVariant),
              ),
            ],
            SizedBox(height: s.spacing.md),
          ],
          child,
        ],
      ),
    );
  }
}
