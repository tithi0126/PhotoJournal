import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/photo_metadata_model.dart';

class ExifDrawer extends StatelessWidget {
  final PhotoMetadataModel metadata;
  final bool hideLocation;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ExifDrawer({
    super.key,
    required this.metadata,
    required this.hideLocation,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle header
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Camera Data',
                  style: AppTypography.mono(
                    fontSize: 11,
                    color: textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSecondary),
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ExifGrid(
              metadata: metadata,
              hideLocation: hideLocation,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accent: accent,
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

class _ExifGrid extends StatelessWidget {
  final PhotoMetadataModel metadata;
  final bool hideLocation;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const _ExifGrid({
    required this.metadata,
    required this.hideLocation,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_ExifRow>[];

    if (metadata.formattedCamera != null) {
      rows.add(_ExifRow(label: 'Camera', value: metadata.formattedCamera!));
    }
    if (metadata.lensModel != null) {
      rows.add(_ExifRow(label: 'Lens', value: metadata.lensModel!));
    }

    // Exposure row: ISO · f/ · shutter · focal
    final exposure = [
      metadata.formattedIso,
      metadata.formattedAperture,
      metadata.formattedShutterSpeed,
      metadata.formattedFocalLength,
    ].where((v) => v != null).join('  ·  ');

    if (exposure.isNotEmpty) {
      rows.add(_ExifRow(label: 'Exposure', value: exposure));
    }

    if (!hideLocation && metadata.hasGps) {
      if (metadata.placeName != null) {
        rows.add(_ExifRow(label: 'Location', value: metadata.placeName!));
      }
      rows.add(_ExifRow(
        label: 'Coordinates',
        value:
            '${metadata.latitude!.toStringAsFixed(5)}, ${metadata.longitude!.toStringAsFixed(5)}',
      ));
    }

    if (rows.isEmpty) {
      return Text(
        'No metadata available for this photo.',
        style: AppTypography.mono(fontSize: 11, color: textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        r.label.toUpperCase(),
                        style: AppTypography.mono(fontSize: 10, color: textSecondary, letterSpacing: 0.6),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: AppTypography.mono(fontSize: 11, color: textPrimary),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ExifRow {
  final String label;
  final String value;
  const _ExifRow({required this.label, required this.value});
}
