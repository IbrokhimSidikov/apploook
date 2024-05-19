

class AddressDetailModel {
  Responset? responset;

  AddressDetailModel({
    required this.responset,
  });

  factory AddressDetailModel.fromJson(Map<String, dynamic> json) =>
      AddressDetailModel(
        responset: Responset.fromJson(json["response"]),
      );
}

class Responset{
  GeoObjectCollection? geoObjectCollection;

  Responset({
    required this.geoObjectCollection,
  });

  factory Responset.fromJson(Map<String, dynamic> json) => Responset(
    geoObjectCollection: json["GeoObjectCollection"] == null
        ? null
        : GeoObjectCollection.fromJson(json["GeoObjectCollection"]),
        ); 
}

class GeoObjectCollection{
  GeoObjectCollectionMetaDataProperty? metaDataProperty;
  List<FeatureMember>? featureMember;

  GeoObjectCollection({
    required this.metaDataProperty,
    required this.featureMember,
  });

  factory GeoObjectCollection.fromJson(Map<String,dynamic> json) => 
      GeoObjectCollection(
        metaDataProperty: json["metaDataProperty"] == null
            ? null
            :GeoObjectCollectionMetaDataProperty.fromJson(
              json["metaDataProperty"]),
        featureMember: List<FeatureMember>.from(
              json["featureMember"].map((x) => FeatureMember.fromJson(x))),
      );
}

class FeatureMember{
  GeoObject? geoObject;

  FeatureMember({
    required this.geoObject,
  });

  factory FeatureMember.fromJson(Map<String, dynamic> json) => FeatureMember(
        geoObject: json["GeoObject"]==null
            ? null
            : GeoObject.fromJson(json["GeoObject"]),
  );
}

class GeoObject{
  GeoObjectMetaDataProperty? metaDataProperty;
  String name;
  String description;
  BoundedBy boundedBy;
  String uri;
  PointModel point;

  GeoObject({
    required this.metaDataProperty,
    required this.name,
    required this.description,
    required this.boundedBy,
    required this.point,
    required this.uri,
  });

  factory GeoObject.fromJson(Map<String, dynamic> json) => GeoObject(
        metaDataProperty: json["metaDataProperty"] == null
            ? null
            : GeoObjectMetaDataProperty.fromJson(json["metaDataProperty"]),
          name: json["name"] ?? "",
          description: json["description"] ?? "",
          boundedBy: json["boundedBy"] == null
              ? BoundedBy(envelope: null)
              : BoundedBy.fromJson(json["boundedBy"]),
          uri: json["uri"] ?? "",
          point: json["Point"] == null
              ? PointModel(pos:"")
              : PointModel.fromJson(json["Point"]),    
        );
}

class BoundedBy{
  Envelope? envelope;

  BoundedBy({
    required this.envelope,
  });

  factory BoundedBy.fromJson(Map<String, dynamic> json) => BoundedBy(
        envelope: json["Envelope"] == null
            ? Envelope(lowerCorner: '', upperCorner: '')
            : Envelope.fromJson(json["Envelope"]), 
        );
}

class Envelope{
  String lowerCorner;
  String upperCorner;

  Envelope({
    required this.lowerCorner,
    required this.upperCorner,
  });

  factory Envelope.fromJson(Map<String, dynamic> json)=> Envelope(
        lowerCorner: json["lowerCorner"] ?? "", 
        upperCorner: json["upperCorner"] ?? "",
      );

}

class GeoObjectMetaDataProperty{
  GeocoderMetaData? geocoderMetaData;

  GeoObjectMetaDataProperty({
    required this.geocoderMetaData,
  });

  factory GeoObjectMetaDataProperty.fromJson(Map<String, dynamic> json) =>
      GeoObjectMetaDataProperty(
        geocoderMetaData: json["GeocoderMetaData"]==null
          ? GeocoderMetaData(
            precision: '',
            text: '',
            addressDetails: null,
            kind: '',
            address: null
          )
          : GeocoderMetaData.fromJson(json["GeocoderMetaData"]),
        );
}

class GeocoderMetaData{
  String precision;
  String text;
  String kind;
  Address? address;
  AddressDetails? addressDetails;

  GeocoderMetaData({
    required this.precision,
    required this.text,
    required this.kind,
    required this.address,
    required this.addressDetails,
  });

  factory GeocoderMetaData.fromJson(Map<String, dynamic> json) =>
      GeocoderMetaData(
        precision: json["precision"] ?? "", 
        text: json["text"] ?? "", 
        kind: json["kind"] ?? "", 
        address: json["Address"] == null
            ? Address(countryCode: '', formatted: '', components: [])
            :Address.fromJson(json["Address"]),    
        addressDetails: json["AddressDetails"] == null
            ?AddressDetails(country: null)
            :AddressDetails.fromJson(json["AddressDetails"]),
      );
}

class Address{
  String countryCode;
  String formatted;
  List<Component> ? components;

  Address({
    required this.components,
    required this.formatted,
    required this.countryCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
      countryCode: json["country_code"]??"", 
      formatted: json["formatted"]??"",
      components: json["Components"]==null
          ?[]
          :List<Component>.from(
            json["Components"].map((x) => Component.fromJson(x))
          ),
          );
}

class Component{
  String kind;
  String name;

  Component({
    required this.kind,
    required this.name,
  });

  factory Component.fromJson(Map<String, dynamic> json) => Component(
        kind: json["kind"] ?? "", 
        name: json["name"] ?? "",
        );
}

class AddressDetails{
  Country? country;

  AddressDetails({
    required this.country,
  });

  factory AddressDetails.fromJson(Map<String, dynamic> json) => AddressDetails(
        country: json["Country"] == null ? null : Country.fromJson(json["Country"]),
        );
}

class Country{
  String addressLine;
  String countryNameCode;
  String countryName;
  AdministrativeArea? administrativeArea;

  Country({
    required this.addressLine,
    required this.countryNameCode,
    required this.countryName,
    required this.administrativeArea,
  });

  factory Country.fromJson(Map<String, dynamic> json)=>Country(
    addressLine: json["AddressLine"]??"", 
    countryNameCode: json["CountryNameCode"]??"", 
    countryName: json["CountyName"]??"", 
    administrativeArea: json["AdministrativeArea"]==null
        ? AdministrativeArea(
          administrativeAreaName: "",
          locality: Locality(
            localityName: "",
            thoroughfare: Thoroughfare(
              thoroughfareName: "",
              premise: Premise(premiseNumber: "")
            ) 
          )
        ):AdministrativeArea.fromJson(json["AdministrativeArea"]),
    );
}

class AdministrativeArea{
  String administrativeAreaName;
  Locality? locality;

  AdministrativeArea({
    required this.administrativeAreaName,
    required this.locality,
  });

  factory AdministrativeArea.fromJson(Map<String, dynamic> json) =>
   AdministrativeArea(
      administrativeAreaName: json["AdministrativeAreaName"]??"",
      locality: json["Locality"] ==null
        ? Locality(localityName: '', thoroughfare: null)
        : Locality.fromJson(json["Locality"]), ); 
}

class Locality{
  String localityName;
  Thoroughfare? thoroughfare;

  Locality({
    required this.localityName,
    required this.thoroughfare,
  });

  factory Locality.fromJson(Map<String, dynamic> json)=>Locality(
    localityName: json["LocalityName"]??"",
    thoroughfare: json["Thoroughfare"]==null
        ?Thoroughfare(premise: Premise(premiseNumber: ""), thoroughfareName: "")
        : Thoroughfare.fromJson(json["Thoroughfare"]),
  );
}

class Thoroughfare{
  String thoroughfareName;
  Premise? premise;

  Thoroughfare({
    required this.premise,
    required this.thoroughfareName,
  });

  factory Thoroughfare.fromJson(Map<String, dynamic> json) => Thoroughfare(
     
    thoroughfareName: json["ThoroughfareName"] ?? "",
    premise: json["Premise"]==null
        ?Premise(premiseNumber: '')
        :Premise.fromJson(json["Premise"]),
        );
}

class Premise{
  String premiseNumber;

  Premise({
    required this.premiseNumber,
  });

  factory Premise.fromJson(Map<String, dynamic> json) => Premise(premiseNumber: json["PremiseNumber"]??"",);
}

class PointModel{
  String pos;

  PointModel({
    required this.pos,
  });

  factory PointModel.fromJson(Map<String, dynamic> json)=>PointModel(pos: json["pos"]??"");
}

class GeoObjectCollectionMetaDataProperty{
  GeocoderResponseMetaData? geocoderResponseMeraData;

  GeoObjectCollectionMetaDataProperty({
    required this.geocoderResponseMeraData,
  });

  factory GeoObjectCollectionMetaDataProperty.fromJson(
    Map<String, dynamic> json) =>
    GeoObjectCollectionMetaDataProperty(geocoderResponseMeraData: json["GeocoderResponseMetaData"]==null
        ?GeocoderResponseMetaData(point: null, request: '', results: '', found: '')
        :GeocoderResponseMetaData.fromJson(json["GeocoderResponseMetaData"]),
        );
}

class GeocoderResponseMetaData{
  PointModel? point;
  String request;
  String results;
  String found;

  GeocoderResponseMetaData({
    required this.point,
    required this.request,
    required this.results,
    required this.found,
  });

  factory GeocoderResponseMetaData.fromJson(Map<String, dynamic> json)=>
      GeocoderResponseMetaData(point: json["Point"]==null?null : PointModel.fromJson(json["Point"]), 
                               request: json["request"]??"", 
                               results: json["results"]??"", 
                               found: json["found"]??"",);
}