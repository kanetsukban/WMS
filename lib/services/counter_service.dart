import '../models/counter_model.dart';

class CounterService {
  void increment(CounterModel counter) {
    counter.value++;
  }
}
