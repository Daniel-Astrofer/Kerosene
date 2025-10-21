


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class ButtonsRow extends StatelessWidget{
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ButtonsRow({super.key,
                    required this.onBack,
                    required this.onNext});

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context,constraints){
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: width / 4,
        children: [
          IconButton(onPressed: onBack, icon: Image.asset('assets/voltarwhite.png',width: 40,height: 40,alignment: Alignment.bottomLeft,),),
          IconButton(onPressed: onNext, icon: Image.asset('assets/seguirwhite.png',width: 40,height: 40,),alignment: Alignment.bottomRight)
        ],
      );

    });
  }
}