



import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/features/authentication/domain/entities/UserDTO.dart';
import 'package:teste/features/authentication/domain/interactors/register_user.dart';

class TotpTextField extends StatefulWidget {
  final
  String totpkey ;
  const TotpTextField({super.key, required this.totpkey});

  @override
  State<TotpTextField> createState() => _TotpTextFieldState();
}

class _TotpTextFieldState extends State<TotpTextField> {

   final f1 = FocusNode();
   final f2 = FocusNode();
   final f3 = FocusNode();
   final f4 = FocusNode();
   final f5 = FocusNode();
   final f6 = FocusNode();

   final c1 = TextEditingController();
   final c2 = TextEditingController();
   final c3 = TextEditingController();
   final c4 = TextEditingController();
   final c5 = TextEditingController();
   final c6 = TextEditingController();
   String ?totpsecret;





   @override
  void dispose() {
    super.dispose();
    f1.dispose();
    f2.dispose();
    f3.dispose();
    f4.dispose();
    f5.dispose();
    f6.dispose();
  }


  @override
  Widget build(BuildContext context) {


    return LayoutBuilder(builder: (context,constraint){


      final width = constraint.maxWidth;

      return Container(
      alignment:Alignment.center,
        width: width * 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

          _TextfieldCustom(f1,f2,c1),
          _TextfieldCustom(f2,f3,c2),
          _TextfieldCustom(f3,f4,c3),
          _TextfieldCustom(f4,f5,c4),
          _TextfieldCustom(f5,f6,c5),
          _TextfieldCustom(f6,null,c6),



        ],),


      );


    });
  }

  Widget _TextfieldCustom(FocusNode current, FocusNode? next,TextEditingController controller){




    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(left: 2,right: 2),
      width: 30,
      height: 30,
      child:
      TextField(
        textAlignVertical: TextAlignVertical.center,
        controller: controller,
        onChanged: (value){
          setState(() {
            totpsecret = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;
          });
          if(value.length == 1 && next != null ){
            next.requestFocus();


          }
          if(totpsecret?.length == 6 ){
            User.instance.setTotpCode(totpsecret!);
            verifytotp(User.instance);
          }
        },
        focusNode: current,

        style: TextStyle(color: Colors.white,fontSize: 15,),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength:1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),

        ],decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.black,
          counterText:''
      ),



      ),

    );



  }


}


