import 'package:flutter/cupertino.dart';

class service extends ChangeNotifier{
  var isDarttheme = false;
  static service instance = service();

  changeTheme(){

    isDarttheme =  !isDarttheme;
    notifyListeners();

  }


}

