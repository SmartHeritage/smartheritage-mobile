import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/config.dart';

void main() {
  test('BEACON_UUIDS nhận dạng liền lẫn có gạch, trả dạng có gạch', () {
    expect(
      AppConfig.parseBeaconUuids(
        'F7826DA64FA24E988024BC5B71E0893E, f7826da6-4fa2-4e98-8024-bc5b71e0893f',
      ),
      [
        'f7826da6-4fa2-4e98-8024-bc5b71e0893e',
        'f7826da6-4fa2-4e98-8024-bc5b71e0893f',
      ],
    );
  });

  test('bỏ qua phần sai định dạng', () {
    expect(AppConfig.parseBeaconUuids(''), isEmpty);
    expect(
      AppConfig.parseBeaconUuids('abc,f7826da64fa24e988024bc5b71e0893'),
      isEmpty,
    );
  });
}
