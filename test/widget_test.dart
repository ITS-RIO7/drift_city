import 'package:flutter_test/flutter_test.dart';

import 'package:drift_city/models/car.dart';

void main() {
  test('car list is well formed', () {
    expect(kCars.length, 10);
    for (final car in kCars) {
      expect(car.speed, inInclusiveRange(0, 1));
      expect(car.grip, inInclusiveRange(0, 1));
      expect(car.drift, inInclusiveRange(0, 1));
      expect(car.length, greaterThan(0));
      expect(car.width, greaterThan(0));
      expect(car.height, greaterThan(0));
    }
    expect(kCars.where((car) => car.price == 0).length, 1);
  });
}
