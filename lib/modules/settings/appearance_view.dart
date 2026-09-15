import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/ui/athar_ui.dart';

/// Appearance: colour theme, display mode, text & interface size, language.
/// Every change applies at once and is kept on the device.
class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LocalizationController>();

    return GetBuilder<ThemeController>(
      builder: (t) => Scaffold(
        appBar: AtharAppBar(title: 'appearance'.tr),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AtharSpace.screen,
            AtharSpace.xs,
            AtharSpace.screen,
            AtharSpace.xxl,
          ),
          children: [
            AtharSectionHeader(
              title: 'appearance_theme'.tr,
              subtitle: 'appearance_theme_sub'.tr,
            ),
            _PresetGrid(selected: t.preset, onSelect: t.setPreset),
            const SizedBox(height: AtharSpace.xl),
            AtharSectionHeader(title: 'appearance_mode'.tr),
            AtharSegmented<AppearanceMode>(
              selected: t.appearance,
              onChanged: t.setAppearance,
              segments: [
                AtharSegment(
                  value: AppearanceMode.system,
                  label: 'mode_system'.tr,
                  icon: Icons.brightness_auto_rounded,
                ),
                AtharSegment(
                  value: AppearanceMode.light,
                  label: 'light'.tr,
                  icon: Icons.light_mode_rounded,
                ),
                AtharSegment(
                  value: AppearanceMode.dark,
                  label: 'dark'.tr,
                  icon: Icons.dark_mode_rounded,
                ),
              ],
            ),
            const SizedBox(height: AtharSpace.xl),
            AtharSectionHeader(title: 'text_size'.tr, subtitle: 'text_size_sub'.tr),
            AtharSegmented<AtharTextSize>(
              selected: t.textSize,
              onChanged: t.setTextSize,
              segments: [
                for (final size in AtharTextSize.values)
                  AtharSegment(value: size, label: size.labelKey.tr),
              ],
            ),
            const SizedBox(height: AtharSpace.sm),
            const _SizePreview(),
            const SizedBox(height: AtharSpace.xl),
            AtharSectionHeader(title: 'language'.tr),
            Obx(
              () => AtharSegmented<String>(
                selected: lang.currentLang.value,
                onChanged: lang.setLanguage,
                segments: const [
                  AtharSegment(value: 'ar', label: 'العربية'),
                  AtharSegment(value: 'en', label: 'English'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({required this.selected, required this.onSelect});

  final AtharThemePreset selected;
  final ValueChanged<AtharThemePreset> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final width = (constraints.maxWidth - AtharSpace.sm * (columns - 1)) / columns;

        return Wrap(
          spacing: AtharSpace.sm,
          runSpacing: AtharSpace.sm,
          children: [
            for (final preset in AtharThemePreset.all)
              SizedBox(
                width: width,
                child: _PresetTile(
                  preset: preset,
                  selected: preset.id == selected.id,
                  onTap: () => onSelect(preset),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A theme as a small picture of itself — its dark and light sides — with its
/// name.
class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.selected, required this.onTap});

  final AtharThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final isDefault = preset.id == AtharThemePreset.defaultPreset.id;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: preset.nameKey.tr,
      child: AnimatedContainer(
        duration: AtharMotion.base,
        curve: AtharMotion.standard,
        decoration: BoxDecoration(
          color: context.athar.card,
          borderRadius: BorderRadius.circular(AtharRadius.card),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AtharRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AtharSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(child: _PresetPreview(preset: preset)),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AtharSpace.xxs,
                      AtharSpace.xs,
                      AtharSpace.xxs,
                      AtharSpace.xxs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.nameKey.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.type.cardTitle,
                              ),
                              if (isDefault)
                                Text('theme_default'.tr, style: context.type.caption),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: AtharMotion.fast,
                          child: Icon(
                            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            key: ValueKey(selected),
                            size: AtharSize.iconLg,
                            color: selected ? scheme.primary : scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Half dark, half light: the preset's colours as they appear in each mode.
class _PresetPreview extends StatelessWidget {
  const _PresetPreview({required this.preset});

  final AtharThemePreset preset;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.colorScheme(preset, Brightness.dark);
    final light = AppTheme.colorScheme(preset, Brightness.light);
    final gold = context.athar.gold;

    Widget side({
      required Color background,
      required Color panel,
      required Color text,
      required Color muted,
      required Color action,
    }) {
      return Container(
        color: background,
        padding: const EdgeInsets.all(AtharSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: gold, shape: BoxShape.circle)),
                const SizedBox(width: AtharSpace.xxs),
                Expanded(child: _Line(color: text, widthFactor: 0.8)),
              ],
            ),
            const Spacer(),
            Container(
              height: 22,
              decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: AlignmentDirectional.centerStart,
              child: _Line(color: muted, widthFactor: 0.6),
            ),
            const SizedBox(height: AtharSpace.xxs),
            Container(
              height: 12,
              width: 36,
              decoration: BoxDecoration(color: action, borderRadius: BorderRadius.circular(AtharRadius.pill)),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AtharRadius.md),
      child: SizedBox(
        height: 92,
        child: Row(
          children: [
            Expanded(
              child: side(
                background: AppTheme.darkBackground(preset),
                panel: dark.surfaceContainer,
                text: dark.onSurface,
                muted: dark.onSurfaceVariant,
                action: dark.primary,
              ),
            ),
            Expanded(
              child: side(
                background: preset.lightBackground,
                panel: light.surfaceContainerLowest,
                text: light.onSurface,
                muted: light.onSurfaceVariant,
                action: light.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: 5,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AtharRadius.pill)),
      ),
    );
  }
}

/// A sample at the chosen size.
class _SizePreview extends StatelessWidget {
  const _SizePreview();

  @override
  Widget build(BuildContext context) {
    return AtharCard(
      tone: AtharCardTone.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('text_size_preview_title'.tr, style: context.type.sectionTitle),
          const SizedBox(height: AtharSpace.xxs),
          Text(
            'text_size_preview_body'.tr,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
