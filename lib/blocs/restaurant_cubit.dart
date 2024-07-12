import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_location/models/restaurants.dart';

class RestaurantCubit extends Cubit<List<Restaurant>> {
  RestaurantCubit() : super([]);

  void addRestaurant(Restaurant restaurant) {
    final updatedList = List<Restaurant>.from(state)..add(restaurant);
    emit(updatedList);
  }
}
