// models/restaurant.dart
import 'package:yandex_mapkit/yandex_mapkit.dart';

class Restaurant {
  final String name;
  final Point location;

  Restaurant({
    required this.name,
    required this.location,
  });
}
