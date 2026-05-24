import 'package:flutter/material.dart';

import '../features/photo_frame/presentation/pages/photo_frame_page.dart';
import 'app_theme.dart';

class ImgFrameApp extends StatelessWidget {
  const ImgFrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'imgFrame',
      theme: buildAppTheme(),
      home: const PhotoFramePage(),
    );
  }
}
