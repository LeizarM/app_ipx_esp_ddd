
import 'dart:convert';

Login loginFromJson(String str) => Login.fromJson(json.decode(str));

String loginToJson(Login data) => json.encode(data.toJson());

class Login {
    String token;
    String bearer;
    String nombreCompleto;
    String cargo;
    String tipoUsuario;
    int codUsuario;
    int codEmpleado;
    int codEmpresa;
    int codCiudad;
    String login;
    String versionApp;
    int codSucursal;
    List<Authority> authorities;

    Login({
        required this.token,
        required this.bearer,
        required this.nombreCompleto,
        required this.cargo,
        required this.tipoUsuario,
        required this.codUsuario,
        required this.codEmpleado,
        required this.codEmpresa,
        required this.codCiudad,
        required this.login,
        required this.versionApp,
        required this.codSucursal,
        required this.authorities,
    });

    factory Login.fromJson(Map<String, dynamic> json) => Login(
        token: json["token"],
        bearer: json["bearer"],
        nombreCompleto: json["nombreCompleto"],
        cargo: json["cargo"],
        tipoUsuario: json["tipoUsuario"],
        codUsuario: json["codUsuario"],
        codEmpleado: json["codEmpleado"],
        codEmpresa: json["codEmpresa"],
        codCiudad: json["codCiudad"],
        login: json["login"],
        versionApp: json["versionApp"],
        codSucursal: json["codSucursal"],
        authorities: List<Authority>.from(json["authorities"].map((x) => Authority.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "token": token,
        "bearer": bearer,
        "nombreCompleto": nombreCompleto,
        "cargo": cargo,
        "tipoUsuario": tipoUsuario,
        "codUsuario": codUsuario,
        "codEmpleado": codEmpleado,
        "codEmpresa": codEmpresa,
        "codCiudad": codCiudad,
        "login": login,
        "versionApp": versionApp,
        "codSucursal": codSucursal,
        "authorities": List<dynamic>.from(authorities.map((x) => x.toJson())),
    };
}

class Authority {
    String authority;

    Authority({
        required this.authority,
    });

    factory Authority.fromJson(Map<String, dynamic> json) => Authority(
        authority: json["authority"],
    );

    Map<String, dynamic> toJson() => {
        "authority": authority,
    };
}
