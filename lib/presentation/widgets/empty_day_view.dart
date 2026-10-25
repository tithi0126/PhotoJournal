import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import 'add_photo_sheet.dart';

/// Shown when a day has no entry — invites the user to add a photo
class EmptyDayView extends ConsumerWidget {
  final String date;
  const EmptyDayView({super.key, required this.date});

  bool get _isToday => DateFormatter.isSameDay(
        DateFormatter.parseIsoDate(date),
        DateTime.now(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final parsedDate = DateFormatter.parseIsoDate(date);
    final dateLabel = DateFormatter.toEditorial(parsedDate);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back button if not today
              if (!_isToday)
                GestureDetector(
                  onTap: () => context.go('/calendar'),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Calendar',
                        style: AppTypography.body(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Date label
              Text(
                dateLabel,
                style: AppTypography.body(fontSize: 12, color: textSecondary),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                _isToday ? 'What did you see today?' : 'Empty frame.',
                style: AppTypography.serifTitle(fontSize: 28, color: textPrimary),
              ),

              const SizedBox(height: 12),

              Text(
                _isToday
                    ? 'One photo. A few words.\nThat\'s all Frame asks.'
                    : 'This day has no photo yet.\nYou can still add one.',
                style: AppTypography.body(fontSize: 15, color: textSecondary, height: 1.6),
              ),

              const SizedBox(height: 40),

              // Add photo button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: const RoundedRectangleBorder(),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: Text(
                    _isToday ? 'Add today\'s photo' : 'Add photo for this day',
                    style: AppTypography.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    AddPhotoFlow.addOrReplacePhoto(
                      context: context,
                      ref: ref,
                      date: date,
                    );
                  },
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
