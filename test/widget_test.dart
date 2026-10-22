import 'package:flutter_test/flutter_test.dart';

import 'package:drift_city/models/car.dart';

void main() {
  test('car list is well formed', () {
    expect(kCars.length, 2);
    expect(kCars.map((c) => c.name).toList(),
        containsAll(<String>['BMW M8', 'Ford Mustang']));
    for (final car in kCars) {
      expect(car.speed, inInclusiveRange(0, 1));
      expect(car.grip, inInclusiveRange(0, 1));
      expect(car.drift, inInclusiveRange(0, 1));
      expect(car.length, greaterThan(0));
      expect(car.width, greaterThan(0));
      expect(car.height, greaterThan(0));
      // Both cars are free.
      expect(car.price, 0);
    }
  });
}
