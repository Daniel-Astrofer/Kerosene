
import 'package:flutter/material.dart';
import 'package:teste/colors.dart';

class TotpHeader extends StatelessWidget{
  const TotpHeader({super.key});

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context,constraints){
      final width = constraints.maxWidth;
      return SizedBox(
        width: width,
        child: Column(
          children: [

            Image.asset('assets/kerosenelogo.png',width: width * 0.25,),
            Text("Verifique sua conta",style:
            TextStyle(
                foreground:
                Paint()..shader = LinearGradient(colors:
                [Cores.instance.cor3,Cores.instance.cor6],).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                fontSize: 27,
                fontFamily: 'HubotSansExpanded',
                fontWeight: FontWeight.w500
            ),),



          ],


        ),
      );

    });

  }



}