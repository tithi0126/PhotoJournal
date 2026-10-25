import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class SheetsScreen extends StatefulWidget {
  const SheetsScreen({super.key});

  @override
  State<SheetsScreen> createState() => _SheetsScreenState();
}

class _SheetsScreenState extends State<SheetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final hairline = isDark ? AppColors.darkHairline : AppColors.lightHairline;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Sheets',
                style: AppTypography.serifTitle(fontSize: 26, color: textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: accent,
              unselectedLabelColor: textSecondary,
              indicatorColor: accent,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: hairline,
              labelStyle: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.body(fontSize: 13),
              tabs: const [
                Tab(text: 'Monthly'),
                Tab(text: 'Yearly'),
                Tab(text: 'Postcards'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _MonthlySheetTab(),
                  _YearlyCollageTab(),
                  _PostcardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly Contact Sheet Tab
// ---------------------------------------------------------------------------

class _MonthlySheetTab extends StatelessWidget {
  const _MonthlySheetTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Generate last 12 months + current
    final months = List.generate(13, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return date;
    }).reversed.toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: months.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final month = months[i];
        final isCurrentMonth = month.month == now.month && month.year == now.year;
        return _SheetCard(
          month: month,
          isCurrent: isCurrentMonth,
        );
      },
    );
  }
}

class _SheetCard extends StatelessWidget {
  final DateTime month;
  final bool isCurrent;

  const _SheetCard({required this.month, required this.isCurrent});

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final hairline = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: hairline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder contact sheet preview
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              color: isDark ? const Color(0xFF111113) : const Color(0xFFF0EFEA),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 32,
                      color: textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCurrent ? 'In progress' : 'Tap to generate',
                      style: AppTypography.mono(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthLabel,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'In progress',
                        style: AppTypography.mono(fontSize: 10, color: accent),
                      ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.ios_share_outlined, size: 18, color: textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yearly Collage Tab
// ---------------------------------------------------------------------------

class _YearlyCollageTab extends StatelessWidget {
  const _YearlyCollageTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final hairline = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateTime.now().year}',
            style: AppTypography.serifTitle(fontSize: 20, color: textPrimary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                border: Border.all(color: hairline, width: 0.5),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 40, color: textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Your ${DateTime.now().year} collage\nwill appear here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(fontSize: 14, color: textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep shooting — add more entries\nto see your year take shape.',
                      textAlign: TextAlign.center,
                      style: AppTypography.mono(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Postcards Tab
// ---------------------------------------------------------------------------

class _PostcardsTab extends StatelessWidget {
  const _PostcardsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_post_office_outlined,
            size: 52,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'Print Your Memories',
            style: AppTypography.serifTitle(fontSize: 22, color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Select 12–15 of your favourite photos\nto create print-ready postcards.',
            style: AppTypography.body(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.12),
              foregroundColor: accent,
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: null, // unlocked when ≥12 entries exist
            child: Text(
              'Start a Postcard Set',
              style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You need at least 12 journal entries.',
            style: AppTypography.mono(fontSize: 11, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
