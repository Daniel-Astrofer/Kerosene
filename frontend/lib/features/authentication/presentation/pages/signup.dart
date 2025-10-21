import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/domain/interactors/register_user.dart';
import 'package:teste/features/authentication/presentation/pages/login.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_card.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_form.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_header.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_row_buttons.dart';



class SignupScreen extends StatelessWidget {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passphraseController = TextEditingController();
  TextEditingController passphrase2Controller = TextEditingController();


  @override
  Widget build(BuildContext context) {

    return  Material(
      child: Scaffold(
        body: LayoutBuilder(builder: (context,constraints){
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return  Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Cores.instance.cor1,Cores.instance.cor6],begin: AlignmentGeometry.topRight,end: AlignmentGeometry.bottomLeft
              ),
            ),

              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SignupCard(usernameController: usernameController,passphraseController: passphraseController,passphrase2Controller: passphrase2Controller),
                  ),
                )
              ),
            );
        })
      ),
    ) ;
  }
}