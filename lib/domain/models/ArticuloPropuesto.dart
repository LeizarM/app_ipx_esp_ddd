// To parse this JSON data, do
import 'dart:convert';

List<ArtciuloPropuesto> artciuloPropuestoFromJson(String str) => List<ArtciuloPropuesto>.from(json.decode(str).map((x) => ArtciuloPropuesto.fromJson(x)));

String artciuloPropuestoToJson(List<ArtciuloPropuesto> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ArtciuloPropuesto {
    String? codArticulo;
    String? datoArt;
    int? listaPrecio;
    double? precio;
    String? moneda;
    int? gramaje;
    int? codigoFamilia;
    int? disponible;
    String? unidadMedida;
    int? codCiudad;
    int? codGrpFamiliaSap;
    String? ruta;
    int? audUsuario;
    String? db;
    dynamic whsCode;
    dynamic whsName;
    String? condicionPrecio;
    dynamic ciudad;
    double? utm;

    ArtciuloPropuesto({
        this.codArticulo,
        this.datoArt,
        this.listaPrecio,
        this.precio,
        this.moneda,
        this.gramaje,
        this.codigoFamilia,
        this.disponible,
        this.unidadMedida,
        this.codCiudad,
        this.codGrpFamiliaSap,
        this.ruta,
        this.audUsuario,
        this.db,
        this.whsCode,
        this.whsName,
        this.condicionPrecio,
        this.ciudad,
        this.utm,
    });

    factory ArtciuloPropuesto.fromJson(Map<String, dynamic> json) => ArtciuloPropuesto(
        codArticulo: json["codArticulo"],
        datoArt: json["datoArt"],
        listaPrecio: json["listaPrecio"],
        precio: json["precio"]?.toDouble(),
        moneda: json["moneda"],
        gramaje: json["gramaje"],
        codigoFamilia: json["codigoFamilia"],
        disponible: json["disponible"],
        unidadMedida: json["unidadMedida"],
        codCiudad: json["codCiudad"],
        codGrpFamiliaSap: json["codGrpFamiliaSap"],
        ruta: json["ruta"],
        audUsuario: json["audUsuario"],
        db: json["db"],
        whsCode: json["whsCode"],
        whsName: json["whsName"],
        condicionPrecio: json["condicionPrecio"],
        ciudad: json["ciudad"],
        utm: json["utm"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "codArticulo": codArticulo,
        "datoArt": datoArt,
        "listaPrecio": listaPrecio,
        "precio": precio,
        "moneda": moneda,
        "gramaje": gramaje,
        "codigoFamilia": codigoFamilia,
        "disponible": disponible,
        "unidadMedida": unidadMedida,
        "codCiudad": codCiudad,
        "codGrpFamiliaSap": codGrpFamiliaSap,
        "ruta": ruta,
        "audUsuario": audUsuario,
        "db": db,
        "whsCode": whsCode,
        "whsName": whsName,
        "condicionPrecio": condicionPrecio,
        "ciudad": ciudad,
        "utm": utm,
    };
}