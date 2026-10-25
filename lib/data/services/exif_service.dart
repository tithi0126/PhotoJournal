import 'dart:convert';
import 'dart:typed_data';
import 'package:exif/exif.dart';
import '../models/photo_metadata_model.dart';

class ExifService {
  /// Extract EXIF metadata from raw image bytes and return a PhotoMetadataModel
  static Future<PhotoMetadataModel> extractMetadata({
    required String photoId,
    required Uint8List bytes,
  }) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) {
        return PhotoMetadataModel(photoId: photoId);
      }

      // Camera Make & Model
      final make = tags['Image Make']?.printable.trim();
      final model = tags['Image Model']?.printable.trim();
      final lensModel = tags['EXIF LensModel']?.printable.trim() ??
          tags['EXIF LensSpecification']?.printable.trim();

      // ISO
      int? iso;
      final isoTag = tags['EXIF ISOSpeedRatings'];
      if (isoTag != null) {
        final val = int.tryParse(isoTag.printable.replaceAll(RegExp(r'[^0-9]'), ''));
        if (val != null) iso = val;
      }

      // Aperture (F-Number)
      double? aperture;
      final fNumberTag = tags['EXIF FNumber'];
      if (fNumberTag != null) {
        aperture = _ratioToDouble(fNumberTag);
      }

      // Shutter Speed (Exposure Time)
      int? shutterNum;
      int? shutterDen;
      final expTag = tags['EXIF ExposureTime'];
      if (expTag != null) {
        final list = expTag.values.toList();
        if (list.isNotEmpty && list.first is Ratio) {
          final r = list.first as Ratio;
          shutterNum = r.numerator;
          shutterDen = r.denominator;
        } else {
          final parts = expTag.printable.split('/');
          if (parts.length == 2) {
            shutterNum = int.tryParse(parts[0].trim());
            shutterDen = int.tryParse(parts[1].trim());
          } else {
            final seconds = double.tryParse(expTag.printable);
            if (seconds != null) {
              if (seconds < 1.0 && seconds > 0) {
                shutterNum = 1;
                shutterDen = (1.0 / seconds).round();
              } else {
                shutterNum = seconds.round();
                shutterDen = 1;
              }
            }
          }
        }
      }

      // Focal Length
      double? focalLengthMm;
      final focalTag = tags['EXIF FocalLength'];
      if (focalTag != null) {
        focalLengthMm = _ratioToDouble(focalTag);
      }

      // Focal Length in 35mm
      double? focal35mm;
      final focal35Tag = tags['EXIF FocalLengthIn35mmFilm'];
      if (focal35Tag != null) {
        focal35mm = double.tryParse(focal35Tag.printable);
      }

      // Capture Date / Time
      int? capturedAt;
      final dateTag = tags['EXIF DateTimeOriginal'] ??
          tags['EXIF DateTimeDigitized'] ??
          tags['Image DateTime'];
      if (dateTag != null) {
        capturedAt = _parseExifDate(dateTag.printable);
      }

      // Orientation
      int? orientation;
      final oriTag = tags['Image Orientation'];
      if (oriTag != null) {
        final list = oriTag.values.toList();
        if (list.isNotEmpty && list.first is int) {
          orientation = list.first as int;
        }
      }

      // GPS Coordinates
      double? lat;
      double? lon;
      double? alt;

      final latTag = tags['GPS GPSLatitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable;
      final lonTag = tags['GPS GPSLongitude'];
      final lonRef = tags['GPS GPSLongitudeRef']?.printable;
      final altTag = tags['GPS GPSAltitude'];

      if (latTag != null && latRef != null) {
        lat = _parseGpsCoord(latTag, latRef);
      }
      if (lonTag != null && lonRef != null) {
        lon = _parseGpsCoord(lonTag, lonRef);
      }
      if (altTag != null) {
        alt = _ratioToDouble(altTag);
      }

      // Raw EXIF JSON summary
      final summaryMap = <String, String>{};
      tags.forEach((k, v) {
        if (!k.startsWith('JPEGThumbnail')) {
          summaryMap[k] = v.printable;
        }
      });
      final rawExif = jsonEncode(summaryMap);

      return PhotoMetadataModel(
        photoId: photoId,
        cameraMake: make,
        cameraModel: model,
        lensModel: lensModel,
        iso: iso,
        aperture: aperture,
        shutterNum: shutterNum,
        shutterDen: shutterDen,
        focalLengthMm: focalLengthMm,
        focal35mm: focal35mm,
        capturedAt: capturedAt,
        latitude: lat,
        longitude: lon,
        altitudeM: alt,
        orientation: orientation,
        rawExifJson: rawExif,
      );
    } catch (_) {
      return PhotoMetadataModel(photoId: photoId);
    }
  }

  static double? _ratioToDouble(IfdTag tag) {
    final list = tag.values.toList();
    if (list.isNotEmpty && list.first is Ratio) {
      final r = list.first as Ratio;
      if (r.denominator != 0) {
        return r.numerator / r.denominator;
      }
    }
    return double.tryParse(tag.printable);
  }

  static int? _parseExifDate(String str) {
    try {
      final parts = str.trim().split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].replaceAll(':', '-');
        final isoStr = '${dateParts}T${parts[1]}';
        final dt = DateTime.tryParse(isoStr);
        if (dt != null) return dt.millisecondsSinceEpoch;
      }
    } catch (_) {}
    return null;
  }

  static double? _parseGpsCoord(IfdTag tag, String ref) {
    try {
      final list = tag.values.toList();
      if (list.length >= 3) {
        double d = _valToDouble(list[0]);
        double m = _valToDouble(list[1]);
        double s = _valToDouble(list[2]);
        double coord = d + (m / 60.0) + (s / 3600.0);
        if (ref.toUpperCase() == 'S' || ref.toUpperCase() == 'W') {
          coord = -coord;
        }
        return coord;
      }
    } catch (_) {}
    return null;
  }

  static double _valToDouble(dynamic val) {
    if (val is Ratio) {
      return val.denominator != 0 ? val.numerator / val.denominator : 0.0;
    }
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
