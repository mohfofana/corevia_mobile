import 'package:corevia_mobile/features/pillbox/domain/entities/paginated_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PaginatedResponse exposes its constructor fields as-is', () {
    final response = PaginatedResponse<int>(
      items: [1, 2, 3],
      page: 1,
      limit: 20,
      total: 3,
    );

    expect(response.items, [1, 2, 3]);
    expect(response.page, 1);
    expect(response.limit, 20);
    expect(response.total, 3);
  });
}
