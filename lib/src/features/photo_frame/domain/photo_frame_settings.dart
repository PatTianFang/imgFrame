import 'frame_options.dart';
import 'frame_style.dart';

class PhotoFrameSettings {
  const PhotoFrameSettings({
    this.style = FrameStyle.softGlow,
    this.options = const FrameOptions(),
  });

  final FrameStyle style;
  final FrameOptions options;

  PhotoFrameSettings copyWith({FrameStyle? style, FrameOptions? options}) {
    return PhotoFrameSettings(
      style: style ?? this.style,
      options: options ?? this.options,
    );
  }

  Map<String, Object?> toMap() {
    return {'style': style.name, 'options': options.toMap()};
  }

  factory PhotoFrameSettings.fromMap(Map<String, Object?> map) {
    return PhotoFrameSettings(
      style: FrameStyle.values.byName(
        map['style'] as String? ?? FrameStyle.softGlow.name,
      ),
      options: FrameOptions.fromMap(
        Map<String, Object?>.from(map['options'] as Map? ?? const {}),
      ),
    );
  }
}
