import 'dart:async';

import 'package:apploook/models/address_detail_model.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:apploook/models/repository/address_detail_repository.dart';
import 'package:apploook/services/app_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:apploook/cart_provider.dart';
import 'package:provider/provider.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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
    var cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          addressDetail,
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
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
                Center(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () async {
                    await _fetchCurrentLocation();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.data_saver_on),
                ),
                FloatingActionButton(
                  // to confirm the location
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
                          content: Text(
                            'Вы подтверждаете свой адрес?\n\n$addressDetail',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Отмена',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context, addressDetail);
                                cartProvider.addLatLong(latLong.lat, latLong.long);
                              },
                              child: Text(
                                'Да', //Confirm the Location
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  backgroundColor: const Color.fromARGB(255, 255, 215, 62),
                  child: Icon(Icons.check),
                ),
              ],
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

    try {
      AddressDetailModel? data = await repository.getAddressDetail(latLong);
      print(data);

      if (data != null && data.responset != null) {
        var geoObjectCollection = data.responset!.geoObjectCollection;
        if (geoObjectCollection != null &&
            geoObjectCollection.featureMember != null &&
            geoObjectCollection.featureMember!.isNotEmpty) {
          var geoObject = geoObjectCollection.featureMember![0].geoObject;
          if (geoObject != null) {
            var geocoderMetaData = geoObject.metaDataProperty?.geocoderMetaData;
            if (geocoderMetaData != null) {
              var address = geocoderMetaData.address;
              if (address != null) {
                addressDetail = address.formatted;
              } else {
                addressDetail = "No address found in GeocoderMetaData";
              }
            } else {
              addressDetail = "No GeocoderMetaData found";
            }
          } else {
            addressDetail = "No GeoObject found";
          }
        } else {
          addressDetail = "No featureMember found";
        }
      } else {
        addressDetail = "No response data found";
        print(addressDetail);
        print(data);
      }
    } catch (e) {
      addressDetail = "Error fetching address details: $e";
    }

    setState(() {});
    print(addressDetail);
  }
}
