import 'dart:async';

import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/address_detail_model.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:apploook/models/repository/address_detail_repository.dart';
import 'package:apploook/services/app_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context).yourLocation,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: () async {
                        await _fetchCurrentLocation();
                      },
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: SvgPicture.asset('images/my_location.svg'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        child: SizedBox(
          height: 160, // Adjust the height as needed to fit your design
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 10.0,
              ),
              Text(
                AppLocalizations.of(context).selectedAddress,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                height: 48,
                width: 363,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(0xFFB0B0B0),
                    ),
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    addressDetail,
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                height: 48,
                width: 363,
                child: ElevatedButton(
                  onPressed: () async {
                    final controller = await mapControllerCompleter.future;
                    final cameraPosition = await controller.getCameraPosition();
                    final latLong = AppLatLong(
                      lat: cameraPosition.target.latitude,
                      long: cameraPosition.target.longitude,
                    );
                    print('Lat: ${latLong.lat}, Long: ${latLong.long}');
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)
                          ),
                          backgroundColor: const Color(0xffffffff),
                          elevation: 5.0,
                          contentPadding: EdgeInsets.only(top: 30, left: 15, right: 15),
                          content: Text(
                            '${AppLocalizations.of(context).confirmAddress}\n\n$addressDetail',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: TextStyle(color: Colors.black26),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context, addressDetail);
                                cartProvider.addLatLong(
                                    latLong.lat, latLong.long);
                              },
                              child: Text(
                                AppLocalizations.of(context).confirm,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color(0xffFEC700), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    elevation: 0, 
                  ),
                  child: Text(
                    AppLocalizations.of(context).save,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    // location = defLocation;
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
