import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';

/// Full-bleed photo viewer with pinch-to-zoom and aspect ratio preservation
class PhotoViewer extends StatelessWidget {
  final String photoPath;
  final int width;
  final int height;

  const PhotoViewer({
    super.key,
    required this.photoPath,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final aspectRatio = width / height;

    // Portrait photos capped at 75% of screen height per PRD §4.4
    double imageHeight = screenWidth / aspectRatio;
    if (imageHeight > screenHeight * 0.75) {
      imageHeight = screenHeight * 0.75;
    }

    final isFile = !photoPath.startsWith('http');

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: SizedBox(
        width: screenWidth,
        height: imageHeight,
        child: isFile
            ? Image.file(
                File(photoPath),
                fit: BoxFit.cover,
                width: screenWidth,
                height: imageHeight,
                errorBuilder: (context, error, stackTrace) => _Placeholder(height: imageHeight),
              )
            : Image.network(
                photoPath,
                fit: BoxFit.cover,
                width: screenWidth,
                height: imageHeight,
                errorBuilder: (context, error, stackTrace) => _Placeholder(height: imageHeight),
              ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => _FullscreenViewer(photoPath: photoPath),
        transitionsBuilder: (context, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  const _Placeholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      color: isDark ? AppColors.darkSurface : AppColors.lightHairline,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 36, color: Colors.grey),
      ),
    );
  }
}

class _FullscreenViewer extends StatelessWidget {
  final String photoPath;
  const _FullscreenViewer({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final isFile = !photoPath.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: isFile
                    ? Image.file(File(photoPath), fit: BoxFit.contain)
                    : Image.network(photoPath, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
