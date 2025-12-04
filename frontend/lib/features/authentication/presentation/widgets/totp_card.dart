



import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/presentation/widgets/totp_header.dart';
import 'package:teste/features/authentication/presentation/widgets/totp_qrcode.dart';
import 'package:teste/features/authentication/presentation/widgets/totp_textfield.dart';

class TotpCard extends StatefulWidget {
  final String totpsecret;

  const TotpCard({super.key,required this.totpsecret});

  @override
  State<TotpCard> createState() => _TotpCardState();
}

class _TotpCardState extends State<TotpCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context,contraints){
      final width  = contraints.maxWidth;
      final height  = contraints.maxHeight;

      return Container(
        alignment: Alignment.center,
        width: width * 0.8,
        height: height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black,spreadRadius: 4,
            blurRadius: 20,
            offset: Offset(2, 2)),

          ],
          border: Border.all(width: 1,color: Colors.black),
            gradient: RadialGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],radius: 2,center: AlignmentGeometry.center)
        ),child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          TotpHeader(),
          Container(height: 50,),

          Text("Escaneie o codigo"),

          TotpQrcode(totpsecret: widget.totpsecret),

          SelectableText("Ou utilize esse codigo no seu aplicativo autenticador :${widget.totpsecret}",enableInteractiveSelection: true,style: TextStyle(
            fontFamily:'assets/SFProDiplay',
            fontWeight: FontWeight.bold,
          ),),

          TotpTextField(totpkey: widget.totpsecret)




        ],
      ),
      );


    });
  }
}
