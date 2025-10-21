import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teste/colors.dart';

class Presentation extends StatelessWidget{

   @override
  Widget build(BuildContext context) {

     return Material(

         child: Stack(
           fit: StackFit.expand,
           alignment: Alignment.center,

           children: [

             Image.asset('assets/presentationimage.png',fit:BoxFit.cover,),
             Center(
               child: Container(
                 height: 400,
                 width: 400,
                 margin: EdgeInsets.only(bottom: 120),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Row(
                       textDirection: TextDirection.ltr,
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [

                         Image.asset('assets/kerosenelogo.png',width: 80,height: 50,),

                         SizedBox(width: 10,),

                         Text("Kerosene",textDirection: TextDirection.ltr,style: TextStyle(
                             fontFamily: 'HubotSans',
                             fontSize: 35,
                             color: Colors.white,
                             fontWeight: FontWeight.bold
                         ),overflow: TextOverflow.ellipsis,),

                       ],
                     ),Container(
                       margin: EdgeInsets.only(left: 27),
                       child: Text("You are the difference.",textDirection: TextDirection.ltr,style: TextStyle(
                           fontFamily: 'HubotSans',
                           fontSize: 10,
                           color: Colors.white,
                           fontWeight: FontWeight.normal
                       ),overflow: TextOverflow.ellipsis,),
                     )
                   ],
                 )

               ),
             ),
             Container(

               margin: EdgeInsets.only(top:200),
               width: 300,
               height: 150,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   GestureDetector(onTap: (){
                     Navigator.of(context).pushNamed('/login');
                   }, child: Container(
                     alignment: Alignment.center,
                     width: 100,
                     height: 45,
                     decoration: BoxDecoration(
                         border: Border.all(color: Cores.instance.cor2,style: BorderStyle.solid,width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Cores.instance.cor2,
                            spreadRadius: 3,
                            blurRadius:15,
                            offset: Offset(2, 4)
                          )
                        ],
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(20),
                         gradient: RadialGradient(colors: [Cores.instance.cor1,Cores.instance.cor4],center: AlignmentGeometry.center,radius:1 )
                     ),

                     child: Text("Login",style: TextStyle(letterSpacing: 2,
                       color: Colors.white,fontSize: 17,fontFamily: 'HubotSans',fontWeight: FontWeight.bold
                     ),),

                   ),),Container(width: 30),
                   GestureDetector( onTap:(){
                     Navigator.of(context).pushNamed('/signup');
                   } ,child: Container(
                     alignment: Alignment.center,
                     width: 100,
                     height: 45,
                     decoration: BoxDecoration(
                       border: Border.all(color: Cores.instance.cor2,style: BorderStyle.solid,width: 1),
                         boxShadow: [
                           BoxShadow(
                               color: Cores.instance.cor2,
                               spreadRadius: 3,
                               blurRadius:15,
                               offset: Offset(2, 4)
                           )
                         ],
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(20),
                         gradient: LinearGradient(colors: [Cores.instance.cor3,Cores.instance.cor4],begin: AlignmentGeometry.bottomLeft ,end: AlignmentGeometry.centerLeft)
                     ),

                     child: Text("Signup",style: TextStyle(letterSpacing: 2,
                         color: Colors.white,fontSize: 17,fontFamily: 'HubotSans',fontWeight: FontWeight.bold,
                     ),),

                   ),),
                 ],
               )
             )

           ],
         ),
       );



     }



}