import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/attraction.dart';

void main() {
  test('đọc khối trên sơ đồ (0..1) và trên bản đồ (lng, lat), bỏ đỉnh lặp', () {
    final a = Attraction.fromJson({
      'id': 'x',
      'name': 'LUK',
      'floorId': 'f1',
      'areaMapBoundary': {
        'type': 'Polygon',
        'coordinates': [
          [
            [0.1, 0.2],
            [0.3, 0.2],
            [0.3, 0.5],
            [0.1, 0.2],
          ],
        ],
      },
      'boundary': {
        'type': 'Polygon',
        'coordinates': [
          [
            [106.8, 10.8],
            [106.81, 10.8],
            [106.81, 10.81],
            [106.8, 10.8],
          ],
        ],
      },
    });

    expect(a.floorId, 'f1');
    expect(a.planBlock, [(0.1, 0.2), (0.3, 0.2), (0.3, 0.5)]);
    expect(a.mapBlock, [(106.8, 10.8), (106.81, 10.8), (106.81, 10.81)]);
  });

  test('khối hỏng hoặc dưới 3 đỉnh thì coi như không có', () {
    final a = Attraction.fromJson({
      'id': 'x',
      'name': 'A',
      'areaMapBoundary': {
        'type': 'Point',
        'coordinates': [0.1, 0.2],
      },
      'boundary': {
        'type': 'Polygon',
        'coordinates': [
          [
            [1, 1],
            [2, 2],
            [1, 1],
          ],
        ],
      },
    });
    expect(a.planBlock, isNull);
    expect(a.mapBlock, isNull);
    expect(a.floorId, isNull);
  });
}
