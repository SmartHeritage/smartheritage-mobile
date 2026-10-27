import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/widgets/artifact_widgets.dart';

void main() {
  // Hiện vật seed có ảnh đóng gói ghép theo tên.
  final packaged = MockData.artifacts.first;

  Artifact withUpload(String? url) => Artifact.fromJson({
    'id': 'uuid-1',
    'name': packaged.name,
    'imageUrl': url,
  });

  ImageProvider shownImage(WidgetTester tester) =>
      tester.widget<Image>(find.byType(Image)).image;

  testWidgets('ảnh admin tải lên thắng ảnh đóng gói cùng tên', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ArtifactThumb(artifact: withUpload('https://cdn.example/a.jpg')),
      ),
    );

    expect(shownImage(tester), isA<NetworkImage>());
  });

  testWidgets('chưa tải ảnh thì dùng ảnh đóng gói', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ArtifactThumb(artifact: withUpload(null))),
    );

    expect(shownImage(tester), isA<AssetImage>());
  });
}
