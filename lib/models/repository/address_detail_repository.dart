import 'package:apploook/models/address_detail_model.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:dio/dio.dart';

class AddressDetailRepository {
  String mapApiKey = "caea5b8e-5833-4148-9c64-c7c62f4d31a3";

  Future<AddressDetailModel?> getAddressDetail(AppLatLong latLong) async {
    try {
      Map<String, String> queryParams = {
        'apikey': mapApiKey,
        'geocode': "${latLong.long},${latLong.lat}",
        'lang': 'uz',
        'format': 'json',
        'results': '1'
      };
      
      Dio yandexDio = Dio();
      var response = await yandexDio.get(
        "https://geocode-maps.yandex.ru/1.x/",
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        return AddressDetailModel.fromJson(response.data);
      } else {
        print("Failed to load address detail: ${response.statusCode}");
        // return null;
      }
    } catch (e) {
      print("Error $e");
    }
    return null;
  }
}
