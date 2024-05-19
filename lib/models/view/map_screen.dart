import 'dart:async';

import 'package:apploook/models/address_detail_model.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:apploook/models/repository/address_detail_repository.dart';
import 'package:apploook/services/app_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapControllerCompleter = Completer<YandexMapController>();
  final AddressDetailRepository repository = AddressDetailRepository();
  String addressDetail = "Map Page";

  @override
  void initState() {
    super.initState();
    _initPermission().ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(addressDetail),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _fetchCurrentLocation();
        },
        backgroundColor: Colors.white,
        child: Icon(Icons.data_saver_on),
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) {
              mapControllerCompleter.complete(controller);
            },
            onCameraPositionChanged: (cameraPosition, reason, finished) {
              if (finished) {
                updateAddressDetail(
                  AppLatLong(
                    lat: cameraPosition.target.latitude,
                    long: cameraPosition.target.longitude,
                  ),
                );
              }
            },
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Icon(
              Icons.location_on,
              color: Colors.red,
              size: 45,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () async {
                final controller = await mapControllerCompleter.future;
                final cameraPosition = await controller.getCameraPosition();
                final latLong = AppLatLong(
                  lat: cameraPosition.target.latitude,
                  long: cameraPosition.target.longitude,
                );

                // Handle the latLong as needed
                print('Lat: ${latLong.lat}, Long: ${latLong.long}');
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Text('Lat: ${latLong.lat}, Long: ${latLong.long}'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.check),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initPermission() async {
    if (!await LocationService().checkPermission()) {
      await LocationService().requestPermission();
    }
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    AppLatLong location;
    const defLocation = TashkentLocation();
    try {
      location = await LocationService().getCurrentLocation();
    } catch (_) {
      location = defLocation;
    }
    location = defLocation;
    updateAddressDetail(location);
    _moveToCurrentLocation(location);
  }

  Future<void> _moveToCurrentLocation(AppLatLong appLatLong) async {
    (await mapControllerCompleter.future).moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            latitude: appLatLong.lat,
            longitude: appLatLong.long,
          ),
          zoom: 15,
        ),
      ),
      animation: const MapAnimation(type: MapAnimationType.linear, duration: 1),
    );
  }

  Future<void> updateAddressDetail(AppLatLong latLong) async {
    setState(() {
      addressDetail = "...loading";
    });
    AddressDetailModel? data = await repository.getAddressDetail(latLong);
    addressDetail = data!.responset!.geoObjectCollection!.featureMember!.isEmpty
        ? "unknown_place"
        : data.responset!.geoObjectCollection!.featureMember![0].geoObject!
            .metaDataProperty!.geocoderMetaData!.address!.formatted!;
    setState(() {});
    print(addressDetail);
  }
}
