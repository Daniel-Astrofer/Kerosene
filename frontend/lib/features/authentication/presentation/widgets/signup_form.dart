


import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/domain/entities/UserDTO.dart';
import 'package:teste/features/authentication/domain/interactors/register_user.dart';
import 'package:teste/features/authentication/domain/validators/passphrase_field_validator.dart';
import 'package:teste/features/authentication/presentation/pages/login.dart';
import 'package:teste/features/authentication/presentation/pages/totp_verification.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_row_buttons.dart';
import 'package:teste/features/authentication/domain/usecases/mnemonic_bip39/bip39.dart';
import 'package:teste/features/authentication/presentation/widgets/totp_qrcode.dart';


class SignupForm extends StatefulWidget {
  final TextEditingController userController;
  final TextEditingController passphraseController;
  bool pressed = true;
  var totpsecret = '';
  final TextEditingController passphrase2Controller;
  final formKey = GlobalKey<FormState>();

  SignupForm({super.key,required this.userController,required this.passphraseController,required this.passphrase2Controller});

  @override
  State<SignupForm> createState() => _SignupFormState();

}

class _SignupFormState extends State<SignupForm> {
  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context,constraints){
      final width = (constraints.maxWidth) * 0.9;
      final height = constraints.maxHeight;
      return Form(
      key: widget.formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          SizedBox(
            width: (width * 0.9),
            child: TextFieldCustom(icon: 'assets/userwhite.png', label: 'User', controller: widget.userController, validator: (value){


              if(value == null || value.isEmpty) {
                return 'nao pode';
              }


            }),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                widget.pressed = false;
              });
            },
            child: widget.pressed
                ? Container(
              width: 100,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Cores.instance.cor4,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 5,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Text(
                "Criar Frase",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'SFProDisplay',
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : Container(
              width: 250,
              height: 75,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Cores.instance.cor5,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 9,
                    spreadRadius: 5,
                    offset: Offset(3, 7),
                  ),
                ],
              ),
              child: ListView(
                scrollDirection: Axis.vertical,

                children: [
                  Text(Bip39.createPhrase(length: MnemonicLength.words18),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'HubotSans',
                      fontWeight: FontWeight.normal,
                      color: Cores.instance.cor3,
                    ),
                  ),
                ],
              )
            ),
          ),

          SizedBox(
            width: (width * 0.9),
            child: TextFieldCustom(icon: 'assets/cadeadowhite.png', label: 'Enter your passphrase', controller: widget.passphraseController, validator: (value){

              if(!Bip39.validatePasspharse(passphrase: value!)){
                return 'not a passphrase';
              }



            } ),
          ),
          SizedBox(
            width: (width * 0.9),
            child: TextFieldCustom(icon: 'assets/cadeadoverify.png', label: 'Passphrase again', controller: widget.passphrase2Controller, validator: (value){

              if(!Bip39.validatePasspharse(passphrase: value!)){
                return 'not a passphrase';
              }



            }) ,
          ),
          ButtonsRow(onBack: () { Navigator.of(context).pushNamed('/init'); }, onNext: () async {

            if(widget.formKey.currentState!.validate()){
              if(await usernameExists(widget.userController.text)){
                final response = await create(widget.userController.text, widget.passphraseController.text);
                setState(() {
                  User.instance.setUsername(widget.userController.text);
                  User.instance.setPassphrase(widget.passphraseController.text);

                  widget.totpsecret = response;
                  User.instance.setTotpSecret(widget.totpsecret);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TotpScreen(totpsecret: widget.totpsecret)));
                });




              }
            }


          })

        ],
      ));



    });

  }
}
