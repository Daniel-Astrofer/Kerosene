


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/presentation/widgets/totp_card.dart';

class TotpScreen extends StatelessWidget{
  final String totpsecret ;
  const TotpScreen({super.key, required this.totpsecret});



  @override
  Widget build(BuildContext context) {

    return Material(
      child: LayoutBuilder(builder: (context,constraints){
        final width = constraints.maxWidth;
        final height = constraints.maxWidth;

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],begin: AlignmentGeometry.topCenter,end: AlignmentGeometry.bottomCenter)
          ),
          width: width,
          height: height,
          child: TotpCard(totpsecret: totpsecret,),
        );

      }),
    );


  }





}