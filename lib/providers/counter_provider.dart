import 'package:flutter/material.dart';
import '../models/counter_model.dart';
import '../services/counter_service.dart';

class CounterProvider with ChangeNotifier {
  final CounterService _service = CounterService();
  CounterModel counter = CounterModel();

  void increment() {
    _service.increment(counter);
    notifyListeners();
  }
}
