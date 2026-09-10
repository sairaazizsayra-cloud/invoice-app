import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/models/date_range.dart';

class DateFilterChips extends StatelessWidget {
  const DateFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DateFilterPreset selected;
  final ValueChanged<DateFilterPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(DateFilterPreset, String)>[
      (DateFilterPreset.today, AppStrings.filterToday),
      (DateFilterPreset.thisWeek, AppStrings.filterThisWeek),
      (DateFilterPreset.thisMonth, AppStrings.filterThisMonth),
      (DateFilterPreset.thisYear, AppStrings.filterThisYear),
      (DateFilterPreset.custom, AppStrings.filterCustom),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.$1 == selected;
          return ChoiceChip(
            label: Text(item.$2),
            selected: isSelected,
            onSelected: (_) => onSelected(item.$1),
          );
        },
      ),
    );
  }
}
