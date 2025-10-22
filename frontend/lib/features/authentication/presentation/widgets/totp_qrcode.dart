
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TotpQrcode extends StatefulWidget {
  const TotpQrcode({super.key, required this.totpsecret});
  final String totpsecret;

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
              QrImageView(data: widget.totpsecret,
                size: 200,
                version: QrVersions.auto,
                backgroundColor: Colors.white,)
            
          ],
        ),
      );
      
    });
  }
}
