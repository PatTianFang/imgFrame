import 'dart:math' as math;

import 'photo_asset.dart';

enum LeicaBadgeAlignment {
  left('左'),
  center('中'),
  right('右');

  const LeicaBadgeAlignment(this.label);

  final String label;
}

enum FrameInfoField {
  camera('相机'),
  lens('镜头'),
  focalLength('焦距'),
  aperture('光圈'),
  shutterSpeed('快门'),
  iso('ISO'),
  dateTime('时间'),
  location('位置');

  const FrameInfoField(this.label);

  final String label;
}

class FrameOptions {
  const FrameOptions({
    this.borderScale = 1,
    this.logoScale = 1,
    this.textScale = 1,
    this.badgeAlignment = LeicaBadgeAlignment.center,
    this.visibleInfoFields = defaultVisibleInfoFields,
    this.deviceNameOverride = '',
  });

  static const defaultVisibleInfoFields = {
    FrameInfoField.camera,
    FrameInfoField.lens,
    FrameInfoField.focalLength,
    FrameInfoField.aperture,
    FrameInfoField.shutterSpeed,
    FrameInfoField.iso,
    FrameInfoField.dateTime,
    FrameInfoField.location,
  };

  final double borderScale;
  final double logoScale;
  final double textScale;
  final LeicaBadgeAlignment badgeAlignment;
  final Set<FrameInfoField> visibleInfoFields;
  final String deviceNameOverride;

  double get normalizedBorderScale => _clampDouble(borderScale, 0.65, 1.8);
  double get normalizedLogoScale => _clampDouble(logoScale, 0.6, 1.8);
  double get normalizedTextScale => _clampDouble(textScale, 0.75, 1.65);

  FrameOptions copyWith({
    double? borderScale,
    double? logoScale,
    double? textScale,
    LeicaBadgeAlignment? badgeAlignment,
    Set<FrameInfoField>? visibleInfoFields,
    String? deviceNameOverride,
  }) {
    return FrameOptions(
      borderScale: borderScale ?? this.borderScale,
      logoScale: logoScale ?? this.logoScale,
      textScale: textScale ?? this.textScale,
      badgeAlignment: badgeAlignment ?? this.badgeAlignment,
      visibleInfoFields: visibleInfoFields ?? this.visibleInfoFields,
      deviceNameOverride: deviceNameOverride ?? this.deviceNameOverride,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'borderScale': borderScale,
      'logoScale': logoScale,
      'textScale': textScale,
      'badgeAlignment': badgeAlignment.name,
      'visibleInfoFields': [for (final field in visibleInfoFields) field.name],
      'deviceNameOverride': deviceNameOverride,
    };
  }

  factory FrameOptions.fromMap(Map<String, Object?> map) {
    return FrameOptions(
      borderScale: (map['borderScale'] as num?)?.toDouble() ?? 1,
      logoScale: (map['logoScale'] as num?)?.toDouble() ?? 1,
      textScale: (map['textScale'] as num?)?.toDouble() ?? 1,
      badgeAlignment: LeicaBadgeAlignment.values.byName(
        map['badgeAlignment'] as String? ?? LeicaBadgeAlignment.center.name,
      ),
      visibleInfoFields: {
        for (final value in (map['visibleInfoFields'] as List? ?? const []))
          FrameInfoField.values.byName(value as String),
      }.ifEmpty(defaultVisibleInfoFields),
      deviceNameOverride: map['deviceNameOverride'] as String? ?? '',
    );
  }

  bool shows(FrameInfoField field) => visibleInfoFields.contains(field);

  String softInfoLine(PhotoExif exif) {
    return [
      cameraInfoLine(exif),
      dateInfoLine(exif),
      exposureInfoLine(exif),
      locationInfoLine(exif),
    ].where((value) => value.isNotEmpty).join('   ');
  }

  String cameraInfoLine(PhotoExif exif) {
    final customDeviceName = deviceNameOverride.trim();
    final parts = [
      if (shows(FrameInfoField.camera))
        customDeviceName.isEmpty ? exif.cameraBodyLine : customDeviceName,
      if (shows(FrameInfoField.lens)) exif.lensLine,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.join('  ');
  }

  String exposureInfoLine(PhotoExif exif) {
    final parts = [
      if (shows(FrameInfoField.focalLength)) exif.focalLength ?? 'No focal',
      if (shows(FrameInfoField.aperture)) exif.aperture ?? 'No aperture',
      if (shows(FrameInfoField.shutterSpeed)) exif.shutterSpeed ?? 'No shutter',
      if (shows(FrameInfoField.iso)) exif.iso ?? 'No ISO',
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.join('  ');
  }

  String dateInfoLine(PhotoExif exif) {
    return shows(FrameInfoField.dateTime) ? exif.dateLine : '';
  }

  String locationInfoLine(PhotoExif exif) {
    return shows(FrameInfoField.location) ? exif.locationLine : '';
  }

  String combinedPrimaryInfoLine(PhotoExif exif) {
    return [
      cameraInfoLine(exif),
      exposureInfoLine(exif),
    ].where((value) => value.isNotEmpty).join('   ');
  }

  String combinedSecondaryInfoLine(PhotoExif exif) {
    return [
      dateInfoLine(exif),
      locationInfoLine(exif),
    ].where((value) => value.isNotEmpty).join('   ');
  }

  static double _clampDouble(double value, double min, double max) {
    if (value.isNaN) {
      return min;
    }
    return math.min(max, math.max(min, value));
  }
}

extension _SetIfEmpty<T> on Set<T> {
  Set<T> ifEmpty(Set<T> fallback) => isEmpty ? fallback : this;
}
