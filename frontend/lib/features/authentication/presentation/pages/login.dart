import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/domain/interactors/register_user.dart';








class CreateAccountScreen extends StatefulWidget{
  TextEditingController usernameController = TextEditingController();
  TextEditingController passphraseController = TextEditingController();
  final formKey = GlobalKey<FormState>() ;
  var usernameError = '';
  @override
  State<StatefulWidget> createState() => CreateAccountScreenState();



}




class CreateAccountScreenState extends State<CreateAccountScreen>{

  var texto = 'Login' ;
  @override
  Widget build(BuildContext context){
    return Material(
        child: Scaffold(
          body:Container(
            width: double.infinity,
            height: double.infinity,
            decoration:BoxDecoration(
              gradient: SweepGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],center: AlignmentGeometry.bottomRight),
            ),child:
          loginContainer(context),),
        ),
      );
  }

  Widget loginContainer(BuildContext context){


    return Center(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(
            color: Colors.black,
            spreadRadius: 1,
            blurRadius: 20,
            offset: Offset(2, 5)
          )],
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],
          begin: AlignmentGeometry.topRight),
        ),
        width: 350,
        height: 500,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(left: 20,top: 20),
              margin: EdgeInsets.zero,
              alignment: Alignment.centerLeft,

              child:
                Text(texto,
                style:TextStyle(
                  color: Colors.white,
                  fontFamily: 'HubotSansExpanded',
                  fontWeight: FontWeight.normal,
                  fontSize: 30
                ),),
            ),
            Container(
              margin: EdgeInsets.only(top: 40,bottom: 40),
              child: Image.asset('assets/kerosenelogo.png',width: 90,height: 40,),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 40),
              padding: EdgeInsets.only(left: 25,right: 25),
              child:Column(
                children: [
                  TextFieldCustom(icon: 'assets/userwhite.png',label:"Username",controller: widget.usernameController, validator: (value){




            }),
                  Container(height: 20,),
                  TextFieldCustom(icon: 'assets/cadeadowhite.png',label: "Passphrase",controller: widget.passphraseController, validator: (value){




                  })
                ],
              ),
            ),
            Container(height: 60,),
            Row(
              spacing: 218,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: (){
                  Navigator.of(context).pushNamed('/init');
                }, icon: Image.asset('assets/voltarwhite.png',width: 40,height: 40,alignment: Alignment.bottomLeft,),),
                IconButton(onPressed: () async {

                  if( await register(widget.usernameController.text,widget.passphraseController.text)){

                    setState(() {
                      texto = "aceito";
                    });
                  }else{
                    setState(() {
                      texto = "nao aceito";
                    });
                  }
                  Text(texto,style: TextStyle(fontSize: 40),);

                }, icon: Image.asset('assets/seguirwhite.png',width: 40,height: 40,),alignment: Alignment.bottomRight)

              ],
            )
          ],
        ),

      ) ,
    );


  }
}

class TextFieldCustom extends StatefulWidget{
  final String icon;
  final String label;
  final String? Function(String?)? validator;




  final TextEditingController controller;


  const TextFieldCustom({super.key,  required this.icon, required this.label, required this.controller, required this.validator});

  @override
  State<TextFieldCustom> createState() => TestFieldCustomState();

}



class TestFieldCustomState extends State<TextFieldCustom>{

  FocusNode _focusNode = FocusNode();
  bool _isFocused = false;



  @override
    void initState(){
    super.initState();
    _focusNode.addListener((){
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

  }

  @override
  Widget build(BuildContext context){


    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Cores.instance.cor2,
            blurRadius: 20,
            spreadRadius: _isFocused ? 12 : 2,
            offset: _isFocused ?  Offset(5, 5):Offset(3, 1)
          )
        ]
      ) ,
      child:TextFormField(
        controller:widget.controller,
        validator: widget.validator,
        focusNode: _focusNode,
        style: TextStyle(

          fontSize: 13,
          fontFamily: 'SFProDisplay',
          fontWeight: FontWeight.bold,
            color: Colors.white
        ),
        decoration: InputDecoration(
          hintText: widget.label,
            hintStyle: TextStyle(
              color: Colors.grey,
                  fontSize: 12,
            ),


            prefixIcon: Padding(padding: EdgeInsets.only(left:10),child:
            Image.asset(widget.icon,width: 20,height: 20,),),
            prefixIconConstraints: BoxConstraints(
                minWidth: 25,
                minHeight: 25
            ),
            filled: true,
            fillColor: Cores.instance.cor1,
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color:Cores.instance.cor3,width: 1)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                gapPadding: 10
            )
        ),
      ),
    );

  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

}


