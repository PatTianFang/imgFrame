enum FrameStyle {
  softGlow('沉浸柔光', 'soft-glow'),
  whiteInfo('白底信息栏', 'white-info');

  const FrameStyle(this.label, this.fileSuffix);

  final String label;
  final String fileSuffix;
}
