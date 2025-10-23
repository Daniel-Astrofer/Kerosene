import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:teste/features/authentication/domain/entities/UserDTO.dart';

Future<bool> register(String username,
                      String passphrase) async{

  
  var url = Uri.parse("https://nan-ichnological-unchidingly.ngrok-free.dev/user/authenticate");
  var response = await http.post(url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'username':username, 'passphrase': passphrase}));

  if(response.statusCode == 200 ) {
    var data = jsonDecode(response.body);

    return true;


  }return false;

}

Future<String> create(String username,String passphrase) async {

  var url = Uri.parse("https://nan-ichnological-unchidingly.ngrok-free.dev/auth/signup");
  var response = await http.post(url,
  headers:{'Content-Type': 'application/json',
  'X-Device-Hash':'seraquedeucerto'},
  body: jsonEncode({'username': username, 'passphrase': passphrase}));
  String body = response.body;
  return body;

}

Future<bool> usernameExists(String username) async{
  final url = Uri.parse("https://nan-ichnological-unchidingly.ngrok-free.dev/auth/usernameExists");
  var response = await http.post(url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'username': username}));

  if(response.statusCode == 202) return true;
  else{
    return false;
  }


}

Future<bool> verifytotp(User user) async{

  final url = Uri.parse("https://nan-ichnological-unchidingly.ngrok-free.dev/auth/code");
  var response = await http.post(url,
      headers: {'Content-Type': 'application/json',
      'X-Device-Hash':'seraquedeucerto'},
      body: jsonEncode({"username": user.username,
        "passphrase": user.passphrase,
        "totpSecret": user.totpSecret,
        "totpCode": user.totpCode}));

  if(response.statusCode == 202) return true;
  else{
    return false;
  }


}