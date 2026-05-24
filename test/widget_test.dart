import 'package:flutter_test/flutter_test.dart';
import 'package:img_frame/src/app/app.dart';

void main() {
  testWidgets('shows empty state before importing photos', (tester) async {
    await tester.pumpWidget(const ImgFrameApp());

    expect(find.text('imgFrame'), findsOneWidget);
    expect(find.text('导入照片后即可生成带 EXIF 参数的边框图'), findsOneWidget);
    expect(find.text('选择照片'), findsOneWidget);
  });
}
