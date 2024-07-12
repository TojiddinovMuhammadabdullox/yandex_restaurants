import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:restaurant_location/blocs/restaurant_cubit.dart';
import 'package:restaurant_location/models/restaurants.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class YandexMapScreen extends StatefulWidget {
  const YandexMapScreen({super.key});

  @override
  State<YandexMapScreen> createState() => _YandexMapScreenState();
}

class _YandexMapScreenState extends State<YandexMapScreen> {
  late YandexMapController mapController;
  final MapObjectId userLocationMapObjectId =
      const MapObjectId('user_location');
  List<MapObject> mapObjects = [];
  final Point initialPoint =
      const Point(latitude: 41.2856806, longitude: 69.2034646);

  @override
  void initState() {
    super.initState();
    mapObjects = [
      PlacemarkMapObject(
        mapId: userLocationMapObjectId,
        point: initialPoint,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/location.png'),
            scale: 1.0,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RestaurantCubit(),
      child: Scaffold(
        body: Stack(
          children: [
            YandexMap(
              onMapCreated: (controller) {
                mapController = controller;
                _moveToInitialLocation();
              },
              onMapTap: _onMapTapped,
              mapObjects: mapObjects,
            ),
            Positioned(
              bottom: 15,
              left: 15,
              child: SizedBox(
                width: 55,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(55),
                    ),
                  ),
                  onPressed: _getCurrentLocation,
                  child: const Icon(CupertinoIcons.location_circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveToInitialLocation() async {
    await mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: initialPoint, zoom: 15.0),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    final Point userLocation =
        Point(latitude: position.latitude, longitude: position.longitude);

    await mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLocation, zoom: 15.0),
      ),
      animation:
          const MapAnimation(type: MapAnimationType.smooth, duration: 1.0),
    );

    setState(() {
      mapObjects
          .removeWhere((element) => element.mapId == userLocationMapObjectId);
      mapObjects.add(
        PlacemarkMapObject(
          mapId: userLocationMapObjectId,
          point: userLocation,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage('assets/location.png'),
              scale: 0.2,
            ),
          ),
        ),
      );
    });
  }

  void _onMapTapped(Point point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddRestaurantForm(point: point);
      },
    );
  }
}

class AddRestaurantForm extends StatefulWidget {
  final Point point;

  const AddRestaurantForm({super.key, required this.point});

  @override
  _AddRestaurantFormState createState() => _AddRestaurantFormState();
}

class _AddRestaurantFormState extends State<AddRestaurantForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: 16.0, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Name of Restaurant'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the restaurant name';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: _saveRestaurant,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRestaurant() {
    if (_formKey.currentState?.validate() ?? false) {
      final restaurant = Restaurant(
        name: _nameController.text,
        location: widget.point,
      );

      context.read<RestaurantCubit>().addRestaurant(restaurant);
      Navigator.pop(context);

      final MapObjectId newRestaurantId = MapObjectId(
          'restaurant_${widget.point.latitude}_${widget.point.longitude}');

      final yandexMapState =
          context.findAncestorStateOfType<_YandexMapScreenState>();
      if (yandexMapState != null) {
        yandexMapState.setState(() {
          yandexMapState.mapObjects.add(
            PlacemarkMapObject(
              mapId: newRestaurantId,
              point: widget.point,
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromAssetImage('assets/marker.png'),
                  scale: 0.2,
                ),
              ),
            ),
          );
        });
      }
    }
  }
}
