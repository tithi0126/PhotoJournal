import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/entry_model.dart';
import '../../../data/models/photo_model.dart';
import '../../../data/services/exif_service.dart';
import '../../../data/services/image_processing_service.dart';
import '../../../providers/entry_providers.dart';

class AddPhotoFlow {
  /// Opens photo picker, processes image & EXIF, saves to DB, and refreshes providers.
  static Future<void> addOrReplacePhoto({
    required BuildContext context,
    required WidgetRef ref,
    required String date,
  }) async {
    final repo = ref.read(entryRepositoryProvider);
    final existingEntry = await repo.getEntryForDate(date);

    if (existingEntry != null && context.mounted) {
      final shouldReplace = await _confirmReplace(context, date);
      if (!shouldReplace) return;
    }

    if (!context.mounted) return;

    // Source selection: Camera or Gallery
    final source = await _selectSource(context);
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 100, // We do our own sizing/compression
      );

      if (pickedFile == null || !context.mounted) return;

      // Show processing dialog
      _showProgressDialog(context);

      final bytes = await pickedFile.readAsBytes();
      final photoId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Process image derivatives & hash
      final processed = await ImageProcessingService.processImage(
        photoId: photoId,
        bytes: bytes,
      );

      // 2. Extract EXIF metadata
      final metadata = await ExifService.extractMetadata(
        photoId: photoId,
        bytes: bytes,
      );

      // 3. Build PhotoModel
      final photo = PhotoModel(
        id: photoId,
        originalPath: processed.originalPath,
        thumbPath: processed.thumbPath,
        mediumPath: processed.mediumPath,
        largePath: processed.largePath,
        width: processed.width,
        height: processed.height,
        fileSize: processed.fileSize,
        mimeType: 'image/jpeg',
        contentHash: processed.contentHash,
        createdAt: now,
      );

      // 4. Save to database
      await repo.insertPhoto(photo);
      await repo.insertPhotoMetadata(metadata);

      String activeEntryId;
      if (existingEntry != null) {
        await repo.replaceEntryPhoto(
          entryId: existingEntry.id,
          newPhotoId: photoId,
          oldPhotoId: existingEntry.photoId,
        );
        activeEntryId = existingEntry.id;
      } else {
        activeEntryId = const Uuid().v4();
        final entry = EntryModel(
          id: activeEntryId,
          entryDate: date,
          photoId: photoId,
          createdAt: now,
          updatedAt: now,
        );
        await repo.insertEntry(entry);
      }

      // 5. Invalidate Riverpod providers to update all screens
      ref.invalidate(todayEntryProvider);
      ref.invalidate(dateThumbMapProvider);
      ref.invalidate(entryByDateProvider(date));

      // Close processing dialog
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 6. Offer optional note/caption sheet
      if (context.mounted) {
        await _showEditCaptionSheet(
          context: context,
          ref: ref,
          entryId: activeEntryId,
          initialTitle: existingEntry?.title,
          initialDescription: existingEntry?.description,
        );
      }
    } catch (e) {
      // Dismiss progress dialog if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photo: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// Dialog confirming photo replacement
  static Future<bool> _confirmReplace(BuildContext context, String date) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Replace photo?',
          style: AppTypography.serifTitle(fontSize: 20, color: textPrimary),
        ),
        content: Text(
          'This day already has a photo. Replace it, or keep it?',
          style: AppTypography.body(fontSize: 14, color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: AppTypography.body(color: textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Replace',
              style: AppTypography.body(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Sheet to choose Camera or Gallery
  static Future<ImageSource?> _selectSource(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    // On macOS desktop, camera might not be supported directly by image_picker,
    // so user can use gallery or camera if available.
    final canUseCamera = Platform.isIOS || Platform.isAndroid;

    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkHairline : AppColors.lightHairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add Photo',
                style: AppTypography.serifTitle(fontSize: 18, color: textPrimary),
              ),
              const SizedBox(height: 16),
              if (canUseCamera)
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: textPrimary),
                  title: Text('Take photo', style: AppTypography.body(color: textPrimary)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: textPrimary),
                title: Text('Choose from library', style: AppTypography.body(color: textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress dialog while ingesting & compressing
  static void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
                const SizedBox(width: 20),
                Text(
                  'Developing photo...',
                  style: AppTypography.body(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Caption & Title sheet (optional, PRD §3.2)
  static Future<void> _showEditCaptionSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String entryId,
    String? initialTitle,
    String? initialDescription,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDescription);

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
                    entryId: entryId,
                    title: title.isEmpty ? null : title,
                    description: desc.isEmpty ? null : desc,
                  );
                  ref.invalidate(todayEntryProvider);
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
}
