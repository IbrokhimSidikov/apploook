import 'package:apploook/models/address_detail_model.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:dio/dio.dart';

class AddressDetailRepository{
 
  String mapApiKey ="824c3368-3c70-4276-9fd0-9f1497d12298";
  @override
  Future<AddressDetailModel?> getAddressDetail(AppLatLong latLong)async{
    try{
      Map<String, String> queryParams = {
        'apikey':mapApiKey,
        'geocode': "${latLong.long}, ${latLong.lat}",
        'lang':'uz',
        'format':'json',
        'results':'1'
      };
      Dio yandexDio = Dio();
      var response = await yandexDio.get(
        "https://geocode-maps.yandex.ru/1.x/",
        queryParameters: queryParams,
      );
      return AddressDetailModel.fromJson(response.data);
    }catch(e){
      print("Error $e");
      
    }
  }
}