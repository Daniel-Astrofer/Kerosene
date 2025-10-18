import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/login/screen.dart';

class signupScreen extends StatelessWidget{


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: mainScreen(),
    );
  }

}

class mainScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {

    return Material(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],begin: AlignmentGeometry.topRight,end: AlignmentGeometry.bottomLeft
            ),
          ),
          child: content() ,
        ),
      ),
    ) ;

  }

}

class content extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 350,
        height: 600,
        decoration:BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(3, 4)
            )
          ],
          gradient: RadialGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],radius: 1,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            Image.asset('assets/kerosenelogo.png',width: 100,height: 40,),
            topContent(),
            fieldContainer(),
            bottomButtons()
          ],
        )


      ) ,
    );
  }

}

class topContent extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Text("Seja bem vindo.",style: TextStyle(

          foreground: Paint()..shader = LinearGradient(colors: [Cores.instance.cor3,Cores.instance.cor6],).createShader(Rect.fromLTWH(0, 0, 200, 70)),
          fontSize: 30,
          fontFamily: 'HubotSansExpanded',
          fontWeight: FontWeight.w500
      ),),
      ],
    );
  }
}
class fieldContainer extends StatefulWidget{
  @override
  State<StatefulWidget> createState()=>fieldContainerState();

}
class fieldContainerState extends State<fieldContainer>{
  bool pressed = false;

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 300,
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          TextFieldCustom('assets/userwhite.png', 'Crie um nome de usuário'),

          GestureDetector(onTap: (){
            setState(() {
              pressed = true;

            });
          },child: pressed ? Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color:Colors.black,
                blurRadius: 9,
                spreadRadius: 5,
                offset: Offset(3, 7))
              ],
              color: Cores.instance.cor5,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(10),
            width: 250,
            height: 75,
            child: Text("dial tooth insect team attitude joy pumpkin sibling suit hammer response fringe thought fine pigeon govern attend toilet",style: TextStyle(
              fontFamily: 'HubotSans',
                fontWeight: FontWeight.normal,
                color: Cores.instance.cor3
            ),) ,
          ): Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black,blurRadius: 5,offset: Offset(2, 4)),
              ],
              color: Cores.instance.cor4,
            ),
            alignment: Alignment.center,

            width: 100,
            height: 20,
            child: Text("Criar Frase",style: TextStyle(fontSize:10,color: Colors.white ,fontFamily: 'SFProDisplay',fontWeight: FontWeight.bold),),
          ),),

          TextFieldCustom('assets/cadeadowhite.png', 'Digite Sua passphrase'),

          TextFieldCustom('assets/cadeadoverify.png', 'Passphrase novamente'),



        ],

      ),
    );
  }
}

class bottomButtons extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 180,
      children: [
        IconButton(onPressed: (){}, icon: Image.asset('assets/voltarwhite.png',width: 40,height: 40,alignment: Alignment.bottomLeft,),),
        IconButton(onPressed: (){}, icon: Image.asset('assets/seguirwhite.png',width: 40,height: 40,),alignment: Alignment.bottomRight)
      ],
    ) ;
  }





}