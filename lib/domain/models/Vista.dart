// To parse this JSON data, do
//
//     final vista = vistaFromJson(jsonString);

import 'dart:convert';

List<Vista> vistaFromJson(String str) => List<Vista>.from(json.decode(str).map((x) => Vista.fromJson(x)));

String vistaToJson(List<Vista> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Vista {
    int codVista;
    int codVistaPadre;
    String direccion;
    String titulo;
    dynamic descripcion;
    dynamic imagen;
    int esRaiz;
    int autorizar;
    int audUsuarioI;
    int fila;
    List<Vista>? items;
    String label;
    int tieneHijo;
    String? routerLink;
    Icon? icon;

    Vista({
        required this.codVista,
        required this.codVistaPadre,
        required this.direccion,
        required this.titulo,
        required this.descripcion,
        required this.imagen,
        required this.esRaiz,
        required this.autorizar,
        required this.audUsuarioI,
        required this.fila,
        required this.items,
        required this.label,
        required this.tieneHijo,
        required this.routerLink,
        required this.icon,
    });

    factory Vista.fromJson(Map<String, dynamic> json) => Vista(
        codVista: json["codVista"],
        codVistaPadre: json["codVistaPadre"],
        direccion: json["direccion"],
        titulo: json["titulo"],
        descripcion: json["descripcion"],
        imagen: json["imagen"],
        esRaiz: json["esRaiz"],
        autorizar: json["autorizar"],
        audUsuarioI: json["audUsuarioI"],
        fila: json["fila"],
        items: json["items"] == null ? [] : List<Vista>.from(json["items"]!.map((x) => Vista.fromJson(x))),
        label: json["label"],
        tieneHijo: json["tieneHijo"],
        routerLink: json["routerLink"],
        icon: iconValues.map[json["icon"]]!,
    );

    Map<String, dynamic> toJson() => {
        "codVista": codVista,
        "codVistaPadre": codVistaPadre,
        "direccion": direccion,
        "titulo": titulo,
        "descripcion": descripcion,
        "imagen": imagen,
        "esRaiz": esRaiz,
        "autorizar": autorizar,
        "audUsuarioI": audUsuarioI,
        "fila": fila,
        "items": items == null ? [] : List<dynamic>.from(items!.map((x) => x.toJson())),
        "label": label,
        "tieneHijo": tieneHijo,
        "routerLink": routerLink,
        "icon": iconValues.reverse[icon],
    };
}

enum Icon {
    PI_PI_CIRCLE
}

final iconValues = EnumValues({
    "pi pi-circle": Icon.PI_PI_CIRCLE
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
