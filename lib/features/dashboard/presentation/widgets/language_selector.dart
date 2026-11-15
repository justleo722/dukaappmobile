import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/l10n/l10n_store.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: L10nStore.languages.containsKey(locale) ? locale : 'en',
            isDense: true,
            isExpanded: false,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            selectedItemBuilder: (context) => L10nStore.languages.values.map((lang) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lang,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            )).toList(),
            // Every language shipped in assets/l10n.
            items: L10nStore.languages.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(value);
              }
            },
          ),
        ),
      ),
    );
  }
}

