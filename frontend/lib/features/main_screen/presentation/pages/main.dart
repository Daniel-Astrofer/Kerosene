import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teste/colors.dart';

import 'package:teste/features/authentication/presentation/pages/login.dart';
import 'package:teste/features/authentication/presentation/pages/begin.dart';
import 'package:teste/features/authentication/presentation/pages/signup.dart';


class MainScreen extends StatelessWidget{
  double sizefont = 12;



  @override
  Widget build(BuildContext context){
    return Material(


        child:  Scaffold(
          backgroundColor: Cores.instance.cor5,
          appBar: AppBar(
            backgroundColor: Cores.instance.cor2,
            title: Container(
              margin: EdgeInsets.only(right: 35),
              alignment: Alignment.center,
              child: Padding(padding: EdgeInsets.all(0),child:
              Image.asset('assets/kerosenelogo.png',alignment: Alignment.center,width: 300,height: 300)
                ,)
            ),
          leading:
            IconButton(onPressed: (){ }, icon:Image.asset('assets/settingswhite.png',alignment: Alignment.centerLeft,width: 30,height: 30),padding: EdgeInsets.all(0),),
          actions: [
            Image.asset('assets/dollarwhite.png',alignment: Alignment.centerLeft,width: 30,height: 30,)

          ],),
          body: ListView(
            padding: EdgeInsets.zero,
            scrollDirection:Axis.vertical,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(color: Colors.blue,
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: Offset(7, 6)
                      )
                    ]
                  ),
                  child: Container(

                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color:Colors.indigo,
                            spreadRadius: 2,
                            blurRadius: 0,
                            offset: Offset(7, 7)
                        )
                      ],
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    alignment: Alignment.center,
                    height: 250,
                    width: 300,
                    child: Container(padding: EdgeInsets.only(bottom: 100)  ,child:
                      Column(mainAxisAlignment: MainAxisAlignment.center,children: [
                        Row(spacing: 10,mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.center,children: [
                          Image.asset('assets/bitcoin.png',width: 30,height: 30,),
                          Text("Bitcoin",style: TextStyle(
                            fontSize: 20,
                              fontFamily:'Lato',
                            fontWeight: FontWeight.bold
                          ),)
                        ],),
                        Text(" BTC : 0.12222 ",style:TextStyle(wordSpacing: 10,color:Colors.black,fontSize: 35,fontFamily:
                        'SFProDisplay',
                        fontWeight: FontWeight.bold),)
                      ],)
                      ,),
                  ),
                ),
              ),

              Column(
                
                children: [
                  Container(padding: EdgeInsets.only(left: 10),margin: EdgeInsets.only(top:30),height: 25,width: 600,decoration:BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Cores.instance.cor2,
                        spreadRadius: 2,
                         blurRadius: 18 ,
                        offset: Offset(0, -4)
                      )
                    ],
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10),topLeft: Radius.circular(10)),
                      color: Cores.instance.cor2
                  ),child: Text("Krinse",style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontFamily: 'SFProDisplay',
                    fontWeight: FontWeight.bold

                  ),),),
                  Container(
                    decoration: BoxDecoration(
                      color: Cores.instance.cor6,
                    ),
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Center(child:
                              Container(
                                margin: EdgeInsets.only(right: 70),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () {},
                                      icon: Image.asset('assets/sendwhite.png', width: 50, height: 40),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                    Text("Enviar",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                                  ],
                                ),
                              )
                          ,),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/receivewhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("Receber",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                              ],
                            ),
                          )
                            ,),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/miningwhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("Minerar",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                              ],
                            ),
                          )
                            ,),
                        ),Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/exportwhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("Exportar",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                              ],
                            ),
                          )
                            ,),
                        ),Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/contactlesswhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("NFC",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold))
                              ],
                            ),
                          )
                            ,),
                        ),
                      ],
                    ),
                  )
                ],
              ),Column(

                children: [
                  Container(padding: EdgeInsets.only(left: 10),margin: EdgeInsets.only(top:10),height: 25,width: 600,decoration:BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Cores.instance.cor2,
                            spreadRadius: 2,
                            blurRadius: 18 ,
                            offset: Offset(0, -4)
                        )
                      ],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(10),topLeft: Radius.circular(10)),
                      color: Cores.instance.cor2
                  ),child: Row(children: [
                    Text("Rede",style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: 'SFProDisplay',
                        fontWeight: FontWeight.bold

                    ),),Text("Bitcoin",style: TextStyle(
                        color: Colors.orange,
                        fontSize: 17,
                        fontFamily: 'SFProDisplay',
                        fontWeight: FontWeight.bold

                    ),)
                  ],)),
                  Container(
                    decoration: BoxDecoration(
                      color: Cores.instance.cor6,
                    ),
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/sendwhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("Enviar",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                              ],
                            ),
                          )
                            ,),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/receivewhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("Receber",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                              ],
                            ),
                          )
                            ,),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Center(child:
                          Container(
                            margin: EdgeInsets.only(right: 70),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Image.asset('assets/miningwhite.png', width: 50, height: 40),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text("Minerar",style: TextStyle(color: Colors.white,fontSize: sizefont,fontFamily: 'Lato',fontWeight: FontWeight.bold),)
                              ],
                            ),
                          )
                            ,),
                        ),
                      ],
                    ),
                  )
                ],
              ),


            ],
          ),
        ),
      );
  }



}


class MainMaterial extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login':(context) => CreateAccountScreen(),
        '/signup':(context) => SignupScreen(),
        '/init': (context)=> Presentation(),
        '/': (context) => MainScreen()
      },initialRoute: '/init',
    );
  }

}