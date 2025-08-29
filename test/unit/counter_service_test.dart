import 'package:flutter_test/flutter_test.dart';
import 'package:wms/models/counter_model.dart';
import 'package:wms/services/counter_service.dart';

void main() {
  test('CounterService increment', () {
    final service = CounterService();
    final counter = CounterModel();
    expect(counter.value, 0);
    service.increment(counter);
    expect(counter.value, 1);
  });
}
