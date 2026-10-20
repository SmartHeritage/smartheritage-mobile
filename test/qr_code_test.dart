import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/services/qr_code.dart';

void main() {
  const id = '3f2a9c1e-5b7d-4e8f-9a0b-1c2d3e4f5a6b';

  test('id trần', () {
    expect(artifactIdCandidates(' $id ').first, id);
  });

  test('link có /artifacts/<id>', () {
    expect(
      artifactIdCandidates('https://smartheritage.vn/artifacts/$id').first,
      id,
    );
  });

  test('deep link smartheritage://artifacts/<id>', () {
    expect(artifactIdCandidates('smartheritage://artifacts/$id').first, id);
  });

  test('query artifactId / id', () {
    expect(artifactIdCandidates('https://x.vn/visit?artifactId=$id').first, id);
    expect(artifactIdCandidates('https://x.vn/a?id=$id').first, id);
  });

  test('chuỗi rỗng thì không có ứng viên', () {
    expect(artifactIdCandidates('   '), isEmpty);
  });
}
