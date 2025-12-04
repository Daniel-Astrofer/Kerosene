import 'package:flutter/cupertino.dart';

class Service extends ChangeNotifier{
  var isDarttheme = false;
  static Service instance = Service();

  changeTheme(){

    isDarttheme =  !isDarttheme;
    notifyListeners();

  }


}

