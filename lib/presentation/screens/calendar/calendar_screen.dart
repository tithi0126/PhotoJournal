import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/entry_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late PageController _pageController;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _pageController = PageController(initialPage: 1200);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final now = DateTime.now();
    final delta = page - 1200;
    var month = now.month + delta;
    var year = now.year;
    while (month > 12) { month -= 12; year++; }
    while (month < 1) { month += 12; year--; }
    return DateTime(year, month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final hairline = isDark ? AppColors.darkHairline : AppColors.lightHairline;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final thumbsAsync = ref.watch(dateThumbMapProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Frame',
                    style: AppTypography.serifTitle(fontSize: 20, color: textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.toMonthYear(_focusedMonth),
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        1200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Today',
                      style: AppTypography.body(fontSize: 13, color: accent),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: hairline, height: 1),

            // Weekday labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: AppTypography.mono(
                                fontSize: 9,
                                color: textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Month page swiper
            Expanded(
              child: thumbsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (thumbs) => PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _focusedMonth = _monthForPage(page));
                  },
                  itemBuilder: (context, page) {
                    final month = _monthForPage(page);
                    return _MonthGrid(
                      month: month,
                      thumbs: thumbs,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      hairline: hairline,
                      onDayTap: (date) => context.go('/day/$date'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, String> thumbs;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color hairline;
  final ValueChanged<String> onDayTap;

  const _MonthGrid({
    required this.month,
    required this.thumbs,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.hairline,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7; // Sun=0
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(month.year, month.month, dayNumber);
        final isoDate = DateFormatter.toIsoDate(date);
        final isToday = DateUtils.isSameDay(date, today);
        final isFuture = date.isAfter(today);
        final thumbPath = thumbs[isoDate];
        final hasEntry = thumbPath != null;

        return GestureDetector(
          onTap: isFuture ? null : () => onDayTap(isoDate),
          child: AnimatedOpacity(
            opacity: isFuture ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(
                border: isToday
                    ? Border.all(color: accent, width: 1.5)
                    : null,
              ),
              child: hasEntry
                  ? Image.file(
                      File(thumbPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _DayNumeral(
                        day: dayNumber,
                        color: textSecondary,
                      ),
                    )
                  : _DayNumeral(day: dayNumber, color: textSecondary),
            ),
          ),
        );
      },
    );
  }
}

class _DayNumeral extends StatelessWidget {
  final int day;
  final Color color;
  const _DayNumeral({required this.day, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$day',
        style: AppTypography.body(fontSize: 11, color: color),
      ),
    );
  }
}
