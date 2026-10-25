class PhotoMetadataModel {
  final String photoId;
  final String? cameraMake;
  final String? cameraModel;
  final String? lensModel;
  final int? iso;
  final double? aperture;
  final int? shutterNum;
  final int? shutterDen;
  final double? focalLengthMm;
  final double? focal35mm;
  final int? capturedAt;
  final int? capturedOffset;
  final bool tzAssumed;
  final double? latitude;
  final double? longitude;
  final double? altitudeM;
  final String? placeName;
  final int? orientation;
  final String? rawExifJson;

  const PhotoMetadataModel({
    required this.photoId,
    this.cameraMake,
    this.cameraModel,
    this.lensModel,
    this.iso,
    this.aperture,
    this.shutterNum,
    this.shutterDen,
    this.focalLengthMm,
    this.focal35mm,
    this.capturedAt,
    this.capturedOffset,
    this.tzAssumed = false,
    this.latitude,
    this.longitude,
    this.altitudeM,
    this.placeName,
    this.orientation,
    this.rawExifJson,
  });

  /// Shutter speed string representation (e.g. "1/250s" or "2s")
  String? get formattedShutterSpeed {
    if (shutterNum == null || shutterDen == null || shutterDen == 0) return null;
    if (shutterNum! >= shutterDen!) {
      final sec = (shutterNum! / shutterDen!).toStringAsFixed(1);
      return '${sec.endsWith(".0") ? sec.substring(0, sec.length - 2) : sec}s';
    }
    return '$shutterNum/${shutterDen}s';
  }

  /// Aperture representation (e.g. "f/2.8")
  String? get formattedAperture {
    if (aperture == null) return null;
    return 'f/${aperture!.toStringAsFixed(1)}';
  }

  /// ISO representation (e.g. "ISO 400")
  String? get formattedIso {
    if (iso == null) return null;
    return 'ISO $iso';
  }

  /// Focal length representation (e.g. "35mm")
  String? get formattedFocalLength {
    if (focalLengthMm == null) return null;
    return '${focalLengthMm!.round()}mm';
  }

  /// Camera info summary (e.g. "Fujifilm X100V")
  String? get formattedCamera {
    if (cameraModel != null && cameraModel!.isNotEmpty) {
      if (cameraMake != null && !cameraModel!.toLowerCase().contains(cameraMake!.toLowerCase())) {
        return '$cameraMake $cameraModel';
      }
      return cameraModel;
    }
    return cameraMake;
  }

  bool get hasGps => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'photo_id': photoId,
      'camera_make': cameraMake,
      'camera_model': cameraModel,
      'lens_model': lensModel,
      'iso': iso,
      'aperture': aperture,
      'shutter_num': shutterNum,
      'shutter_den': shutterDen,
      'focal_length_mm': focalLengthMm,
      'focal_35mm': focal35mm,
      'captured_at': capturedAt,
      'captured_offset': capturedOffset,
      'tz_assumed': tzAssumed ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'altitude_m': altitudeM,
      'place_name': placeName,
      'orientation': orientation,
      'raw_exif_json': rawExifJson,
    };
  }

  factory PhotoMetadataModel.fromMap(Map<String, dynamic> map) {
    return PhotoMetadataModel(
      photoId: map['photo_id'] as String,
      cameraMake: map['camera_make'] as String?,
      cameraModel: map['camera_model'] as String?,
      lensModel: map['lens_model'] as String?,
      iso: map['iso'] as int?,
      aperture: (map['aperture'] as num?)?.toDouble(),
      shutterNum: map['shutter_num'] as int?,
      shutterDen: map['shutter_den'] as int?,
      focalLengthMm: (map['focal_length_mm'] as num?)?.toDouble(),
      focal35mm: (map['focal_35mm'] as num?)?.toDouble(),
      capturedAt: map['captured_at'] as int?,
      capturedOffset: map['captured_offset'] as int?,
      tzAssumed: (map['tz_assumed'] as int? ?? 0) == 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitudeM: (map['altitude_m'] as num?)?.toDouble(),
      placeName: map['place_name'] as String?,
      orientation: map['orientation'] as int?,
      rawExifJson: map['raw_exif_json'] as String?,
    );
  }
}
