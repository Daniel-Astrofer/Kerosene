


import 'package:flutter/material.dart';
import 'package:teste/colors.dart';

class SignupTopContent extends StatelessWidget{

  const SignupTopContent({super.key});


  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context,constraints){
      final width = constraints.maxWidth;

      return Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/kerosenelogo.png',width: (width * 0.25)),
          SizedBox(
            width: (width * 0.75),
            child: FittedBox(
              alignment: Alignment.center,
              fit: BoxFit.contain,
              child: Text("Seja bem vindo.",style:
              TextStyle(
                  foreground:
                  Paint()..shader = LinearGradient(colors:
                  [Cores.instance.cor3,Cores.instance.cor6],).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                  fontSize: 30,
                  fontFamily: 'HubotSansExpanded',
                  fontWeight: FontWeight.w500
              ),),
            )
          )
        ],
      );

    });

  }




}