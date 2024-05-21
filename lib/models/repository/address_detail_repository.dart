import 'package:apploook/models/address_detail_model.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:dio/dio.dart';

class AddressDetailRepository {
  String mapApiKey = "a0ba4035-8bc1-4f5a-98f6-e15b320a2d4e";

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
