import 'package:flutter/material.dart';

import '../../domain/frame_style.dart';

class StyleSelector extends StatelessWidget {
  const StyleSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final FrameStyle value;
  final ValueChanged<FrameStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('边框样式', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SegmentedButton<FrameStyle>(
          segments: const [
            ButtonSegment(
              value: FrameStyle.softGlow,
              icon: Icon(Icons.blur_on_outlined),
              label: Text('柔光'),
            ),
            ButtonSegment(
              value: FrameStyle.whiteInfo,
              icon: Icon(Icons.view_agenda_outlined),
              label: Text('信息栏'),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (selected) => onChanged(selected.first),
        ),
      ],
    );
  }
}
