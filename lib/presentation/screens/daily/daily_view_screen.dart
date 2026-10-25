import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/entry_model.dart';
import '../../../providers/entry_providers.dart';
import '../../widgets/photo_viewer.dart';
import '../../widgets/exif_drawer.dart';
import '../../widgets/empty_day_view.dart';
import '../../widgets/add_photo_sheet.dart';

class DailyViewScreen extends ConsumerStatefulWidget {
  final String date;
  const DailyViewScreen({super.key, required this.date});

  @override
  ConsumerState<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends ConsumerState<DailyViewScreen> {
  bool _metaExpanded = false;

  Future<void> _navigateToDate(BuildContext context, WidgetRef ref, bool goNext) async {
    final repo = ref.read(entryRepositoryProvider);
    final date = goNext
        ? await repo.getNextEntryDate(widget.date)
        : await repo.getPreviousEntryDate(widget.date);
    if (date != null && context.mounted) {
      context.go('/day/$date');
    }
  }

  Future<void> _editCaption(EntryModel entry) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final titleController = TextEditingController(text: entry.title);
    final descController = TextEditingController(text: entry.description);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Words for this day',
                  style: AppTypography.serifTitle(fontSize: 18, color: textPrimary),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Done', style: AppTypography.body(color: accent, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: 'Title (optional, max 60 chars)',
                hintStyle: AppTypography.body(color: textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
              style: AppTypography.serifTitle(fontSize: 18, color: textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLength: 280,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'A few thoughts... (optional, max 280 chars)',
                hintStyle: AppTypography.body(color: textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
              style: AppTypography.body(fontSize: 14, color: textPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: const RoundedRectangleBorder(),
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  final repo = ref.read(entryRepositoryProvider);
                  await repo.updateEntryText(
                    entryId: entry.id,
                    title: title.isEmpty ? null : title,
                    description: desc.isEmpty ? null : desc,
                  );
                  ref.invalidate(todayEntryProvider);
                  ref.invalidate(entryByDateProvider(widget.date));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  'Save words',
                  style: AppTypography.body(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(EntryModel entry) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete entry?',
          style: AppTypography.serifTitle(fontSize: 20, color: textPrimary),
        ),
        content: Text(
          'This will remove the photo for this day. You can add another photo at any time.',
          style: AppTypography.body(fontSize: 14, color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTypography.body(color: textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AppTypography.body(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(entryRepositoryProvider);
      await repo.softDeleteEntry(entry.id);
      ref.invalidate(todayEntryProvider);
      ref.invalidate(dateThumbMapProvider);
      ref.invalidate(entryByDateProvider(widget.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final hairline = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    final entryAsync = ref.watch(entryByDateProvider(widget.date));

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 200) {
            _navigateToDate(context, ref, false);
          } else if (details.primaryVelocity! < -200) {
            _navigateToDate(context, ref, true);
          }
        },
        child: entryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (entry) {
            if (entry == null) return EmptyDayView(date: widget.date);

            final photo = entry.photo;
            final meta = entry.metadata;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => context.go('/calendar'),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: () => context.go('/calendar'),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, color: textPrimary),
                      onSelected: (val) async {
                        if (val == 'replace') {
                          await AddPhotoFlow.addOrReplacePhoto(
                            context: context,
                            ref: ref,
                            date: widget.date,
                          );
                        } else if (val == 'edit') {
                          await _editCaption(entry);
                        } else if (val == 'location') {
                          final repo = ref.read(entryRepositoryProvider);
                          await repo.setHideLocation(
                            entryId: entry.id,
                            hide: !entry.hideLocation,
                          );
                          ref.invalidate(entryByDateProvider(widget.date));
                        } else if (val == 'delete') {
                          await _confirmDelete(entry);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'replace',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Replace photo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Edit title & thoughts'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'location',
                          child: Row(
                            children: [
                              Icon(
                                entry.hideLocation
                                    ? Icons.location_on_outlined
                                    : Icons.location_off_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(entry.hideLocation ? 'Show location' : 'Hide location'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red.shade400),
                              const SizedBox(width: 8),
                              Text('Delete entry',
                                  style: TextStyle(color: Colors.red.shade400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo != null)
                        PhotoViewer(
                          photoPath: photo.largePath,
                          width: photo.width,
                          height: photo.height,
                        ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          DateFormatter.toEditorial(
                              DateFormatter.parseIsoDate(entry.entryDate)),
                          style: AppTypography.body(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (entry.title != null && entry.title!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _editCaption(entry),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              entry.title!,
                              style: AppTypography.serifTitle(
                                fontSize: 22,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      if (entry.description != null && entry.description!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _editCaption(entry),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              entry.description!,
                              style: AppTypography.body(fontSize: 15, color: textPrimary),
                            ),
                          ),
                        ),

                      // Add note prompt if empty
                      if ((entry.title == null || entry.title!.isEmpty) &&
                          (entry.description == null || entry.description!.isEmpty))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: () => _editCaption(entry),
                            child: Row(
                              children: [
                                Icon(Icons.edit_note_rounded, size: 16, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Add a note or title...',
                                  style: AppTypography.body(fontSize: 13, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                      Divider(color: hairline, height: 1),

                      if (meta != null) ...[
                        ExifDrawer(
                          metadata: meta,
                          hideLocation: entry.hideLocation,
                          isExpanded: _metaExpanded,
                          onToggle: () => setState(() => _metaExpanded = !_metaExpanded),
                        ),
                        Divider(color: hairline, height: 1),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
