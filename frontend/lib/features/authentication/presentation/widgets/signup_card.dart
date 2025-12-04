import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_form.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_header.dart';class SignupCard extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passphraseController;
  final TextEditingController passphrase2Controller;

  const SignupCard({super.key, required this.usernameController,required this.passphraseController,required this.passphrase2Controller});

  @override
  State<SignupCard> createState() => _SignupCardState();
}

class _SignupCardState extends State<SignupCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context,constraints){
      final width = constraints.maxWidth;


      return Center(
        child: Container(
          margin: EdgeInsets.only(top: width / 4),
            width: (width * 0.8),
            height: width * 1.7,
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
              spacing: width * 0.4 ,
              mainAxisSize: MainAxisSize.min,

              children: [
                SignupTopContent(),
                Column(
                  spacing: width * 0.4,
                  children: [

                    SignupForm(userController: widget.usernameController, passphraseController: widget.passphraseController, passphrase2Controller: widget.passphrase2Controller),
                      ],
                )
              ],
            )
        ) ,
      );
    });
  }
}
