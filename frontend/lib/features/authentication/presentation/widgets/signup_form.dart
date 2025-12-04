import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/domain/entities/user_dto.dart';
import 'package:teste/features/authentication/domain/interactors/register_user.dart';
import 'package:teste/features/authentication/presentation/pages/totp_verification.dart';
import 'package:teste/features/authentication/presentation/widgets/signup_row_buttons.dart';
import 'package:teste/features/authentication/domain/usecases/mnemonic_bip39/bip39.dart';

// Custom TextField Widget
class TextFieldCustom extends StatelessWidget {
  final String icon;
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;

  const TextFieldCustom({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Image.asset(icon, width: 24, height: 24),
        filled: true,
        fillColor: Colors.black.withAlpha(50),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Cores.instance.cor3),
        ),
      ),
    );
  }
}


class SignupForm extends StatefulWidget {
  final TextEditingController userController;
  final TextEditingController passphraseController;
  final TextEditingController passphrase2Controller;
  final formKey = GlobalKey<FormState>();

  SignupForm({super.key,required this.userController,required this.passphraseController,required this.passphrase2Controller});

  @override
  State<SignupForm> createState() => _SignupFormState();

}

class _SignupFormState extends State<SignupForm> {
  bool pressed = true;
  var totpsecret = '';

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context,constraints){
      final width = (constraints.maxWidth) * 0.9;

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
              return null;


            }),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                pressed = false;
              });
            },
            child: pressed
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
              return null;



            } ),
          ),
          SizedBox(
            width: (width * 0.9),
            child: TextFieldCustom(icon: 'assets/cadeadoverify.png', label: 'Passphrase again', controller: widget.passphrase2Controller, validator: (value){

              if(!Bip39.validatePasspharse(passphrase: value!)){
                return 'not a passphrase';
              }
              return null;



            }) ,
          ),
          ButtonsRow(onBack: () { Navigator.of(context).pushNamed('/init'); }, onNext: () async {

            if(widget.formKey.currentState!.validate()){

                final response = await create(widget.userController.text, widget.passphraseController.text);
                setState(() {
                  User.instance.username = widget.userController.text;
                  User.instance.passphrase = widget.passphraseController.text;

                  totpsecret = response;
                  User.instance.totpSecret = totpsecret;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TotpScreen(totpsecret: totpsecret)));
                });





            }


          })

        ],
      ));



    });

  }
}
