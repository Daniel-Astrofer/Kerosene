package com.example.again





fun Verify(email:String,senha:String) : Boolean{


    val emailRegex = Regex("^[a-z0-9.]+@[a-z0-9]+\\.[a-z]+(\\.[a-z]+)?$", RegexOption.IGNORE_CASE)
    val emailV = emailRegex.matches(email)


    val senhaRegex = Regex("^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[$*.&@#])[0-9a-zA-Z$*.&@#]{8,}$")
    val senhaV = senhaRegex.matches(senha)

    return (senhaV && emailV)


}



