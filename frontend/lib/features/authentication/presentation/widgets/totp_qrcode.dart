
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/features/authentication/domain/entities/UserDTO.dart';

class TotpQrcode extends StatefulWidget {
  TotpQrcode({super.key, required this.totpsecret});
  final String totpsecret;
  late String  otpPauth = "otpauth://totp/Kerosene:${User.instance.username}?secret=${totpsecret}&issuer=Kerosene&algorithm=SHA1&digits=6&period=30";

  @override
  State<TotpQrcode> createState() => _TotpQrcodeState();
}

class _TotpQrcodeState extends State<TotpQrcode> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context,constraint){
      
      
      return Container(
        child:
        Column(
          children: [
            
            if(widget.totpsecret.isNotEmpty)
              QrImageView(data: widget.otpPauth,
                size: 200,
                version: QrVersions.auto,
                backgroundColor: Colors.white,)
            
          ],
        ),
      );
      
    });
  }
}
